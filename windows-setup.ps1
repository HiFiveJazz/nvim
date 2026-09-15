#Requires -Version 5.1
<#
.SYNOPSIS
    Bootstrap a Windows machine for this Neovim configuration.

.DESCRIPTION
    Installs the Windows-side dependencies used by this Neovim setup:
      - Neovim, Git, PowerShell 7
      - ripgrep, fd, Deno, Node.js LTS
      - LLVM/clang/clangd
      - Visual Studio C++ Build Tools + Windows SDK
      - Rust/rustup
      - 7-Zip
      - Yazi
      - JetBrains Mono Nerd Font
      - tree-sitter CLI
      - lazygitrs
      - Neovim Node and Python providers
      - SQLite DLL for NeoComposer/sqlite.lua

    It also:
      - Adds LLVM and 7-Zip to the user PATH when present
      - Configures YAZI_FILE_ONE to use Git for Windows' file.exe
      - Optionally clones a Yazi config repo

    Run from PowerShell:
        Set-ExecutionPolicy -Scope Process Bypass
        .\windows-setup.ps1

    Optional:
        .\windows-setup.ps1 -YaziConfigRepo "https://github.com/USER/yazi-config.git"

.NOTES
    Some installers can trigger UAC prompts.
    After the script finishes, restart Windows Terminal before testing everything.
#>

[CmdletBinding()]
param(
    [string]$YaziConfigRepo = "",
    [switch]$SkipBuildTools,
    [switch]$SkipSQLite
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Test-Command {
    param([string]$Name)
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Refresh-Path {
    $machine = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $user = [Environment]::GetEnvironmentVariable("Path", "User")
    $env:Path = "$machine;$user"
}

function Add-UserPath {
    param([string]$PathToAdd)

    if (-not (Test-Path $PathToAdd)) {
        return
    }

    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $parts = @()
    if ($userPath) {
        $parts = $userPath.Split(";") | Where-Object { $_ }
    }

    if ($parts -notcontains $PathToAdd) {
        $newPath = if ($userPath) { "$userPath;$PathToAdd" } else { $PathToAdd }
        [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
        Write-Host "Added to user PATH: $PathToAdd"
    }
}

function Install-WingetPackage {
    param(
        [Parameter(Mandatory=$true)][string]$Id,
        [string]$Override = ""
    )

    Write-Host "Installing/updating $Id ..."

    $args = @(
        "install",
        "--id", $Id,
        "-e",
        "--accept-package-agreements",
        "--accept-source-agreements"
    )

    if ($Override) {
        $args += @("--override", $Override)
    }

    & winget @args

    # winget returns non-zero in a few benign "already installed/no upgrade" cases,
    # so do not abort the entire bootstrap solely on its exit code.
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "winget returned exit code $LASTEXITCODE for $Id. Review the output above."
    }
}

if (-not (Test-Command winget)) {
    throw "winget was not found. Install/update 'App Installer' from Microsoft, then rerun this script."
}

Write-Step "Updating winget sources"
winget source update | Out-Host

Write-Step "Installing core tools"
$corePackages = @(
    "Neovim.Neovim",
    "Git.Git",
    "Microsoft.PowerShell",
    "BurntSushi.ripgrep.MSVC",
    "sharkdp.fd",
    "DenoLand.Deno",
    "OpenJS.NodeJS.LTS",
    "LLVM.LLVM",
    "Rustlang.Rustup",
    "7zip.7zip",
    "sxyazi.yazi",
    "DEVCOM.JetBrainsMonoNerdFont"
)

foreach ($pkg in $corePackages) {
    Install-WingetPackage -Id $pkg
}

if (-not $SkipBuildTools) {
    Write-Step "Installing Visual Studio C++ Build Tools"
    Install-WingetPackage `
        -Id "Microsoft.VisualStudio.2022.BuildTools" `
        -Override "--add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.Windows11SDK.22621 --addProductLang En-us"
}

Write-Step "Adding native tool directories to PATH"
Add-UserPath "C:\Program Files\LLVM\bin"
Add-UserPath "C:\Program Files\7-Zip"
Refresh-Path

# cargo is normally placed here by rustup. Add it for this process in case
# rustup was installed during this run and the shell has not been restarted yet.
$cargoBin = Join-Path $HOME ".cargo\bin"
if (Test-Path $cargoBin) {
    Add-UserPath $cargoBin
}
Refresh-Path

Write-Step "Configuring Yazi MIME detection"
$gitFile = "C:\Program Files\Git\usr\bin\file.exe"
if (Test-Path $gitFile) {
    [Environment]::SetEnvironmentVariable("YAZI_FILE_ONE", $gitFile, "User")
    $env:YAZI_FILE_ONE = $gitFile
    Write-Host "YAZI_FILE_ONE=$gitFile"
} else {
    Write-Warning "Git's file.exe was not found at '$gitFile'. Yazi MIME detection may need manual configuration."
}

Write-Step "Installing tree-sitter CLI"
if (Test-Command cargo) {
    cargo install tree-sitter-cli --locked
} else {
    Write-Warning "cargo is not available in this shell yet. Restart the terminal and run: cargo install tree-sitter-cli --locked"
}

Write-Step "Installing lazygitrs"
if (Test-Command npm) {
    # lazygitrs uses a postinstall script to install its Windows binary.
    npm install -g --allow-scripts=lazygitrs lazygitrs
} else {
    Write-Warning "npm is not available in this shell yet. Restart the terminal and run: npm install -g --allow-scripts=lazygitrs lazygitrs"
}

Write-Step "Installing Neovim Node provider"
if (Test-Command npm) {
    npm install -g neovim
}

Write-Step "Installing Neovim Python provider"
if (Test-Command python) {
    python -m pip install --user --upgrade pynvim
} elseif (Test-Command py) {
    py -m pip install --user --upgrade pynvim
} else {
    Write-Warning "Python was not found. If your config needs the Python provider, install Python and then run: python -m pip install --user pynvim"
}

if (-not $SkipSQLite) {
    Write-Step "Installing SQLite DLL for NeoComposer/sqlite.lua"

    $sqliteDir = Join-Path $env:LOCALAPPDATA "nvim-data\sqlite"
    New-Item -ItemType Directory -Force -Path $sqliteDir | Out-Null
    $sqliteDll = Join-Path $sqliteDir "sqlite3.dll"

    try {
        # Discover the current Windows x64 DLL archive from SQLite's download page
        # instead of pinning a version-specific URL.
        $downloadPage = Invoke-WebRequest -UseBasicParsing "https://www.sqlite.org/download.html"
        $match = [regex]::Match(
            $downloadPage.Content,
            '(?<path>[0-9]{4}/sqlite-dll-win-x64-[0-9]+\.zip)'
        )

        if (-not $match.Success) {
            throw "Could not discover sqlite-dll-win-x64 archive from sqlite.org."
        }

        $sqliteUrl = "https://www.sqlite.org/" + $match.Groups["path"].Value
        $sqliteZip = Join-Path $env:TEMP "sqlite-dll-win-x64.zip"
        $sqliteExtract = Join-Path $env:TEMP "sqlite-dll-win-x64"

        Remove-Item $sqliteZip -Force -ErrorAction SilentlyContinue
        Remove-Item $sqliteExtract -Recurse -Force -ErrorAction SilentlyContinue

        Invoke-WebRequest -UseBasicParsing $sqliteUrl -OutFile $sqliteZip
        Expand-Archive -Path $sqliteZip -DestinationPath $sqliteExtract -Force

        $foundDll = Get-ChildItem $sqliteExtract -Recurse -Filter "sqlite3.dll" | Select-Object -First 1
        if (-not $foundDll) {
            throw "sqlite3.dll was not found in the downloaded archive."
        }

        Copy-Item $foundDll.FullName $sqliteDll -Force
        Write-Host "Installed SQLite DLL: $sqliteDll"
        Write-Host ""
        Write-Host "Your Neovim config should contain this Windows-only setting BEFORE NeoComposer setup:"
        Write-Host '  if vim.fn.has("win32") == 1 then'
        Write-Host '    vim.g.sqlite_clib_path = (vim.fn.stdpath("data") .. "/sqlite/sqlite3.dll"):gsub("\\", "/")'
        Write-Host '  end'
    }
    catch {
        Write-Warning "SQLite DLL setup failed: $($_.Exception.Message)"
        Write-Warning "Download the Windows x64 SQLite DLL manually and place sqlite3.dll in: $sqliteDir"
    }
}

if ($YaziConfigRepo) {
    Write-Step "Installing Yazi configuration"
    $yaziConfigDir = Join-Path $env:APPDATA "yazi\config"

    if (Test-Path (Join-Path $yaziConfigDir ".git")) {
        Write-Host "Yazi config repo already exists; pulling latest changes."
        git -C $yaziConfigDir pull --ff-only
    }
    elseif (Test-Path $yaziConfigDir) {
        Write-Warning "Yazi config directory already exists but is not a Git repo: $yaziConfigDir"
        Write-Warning "Leaving it untouched. Move/remove it and rerun with -YaziConfigRepo if desired."
    }
    else {
        git clone $YaziConfigRepo $yaziConfigDir
    }
}

Refresh-Path

Write-Step "Verification"
$checks = @(
    @{ Name = "nvim"; Args = @("--version") },
    @{ Name = "git"; Args = @("--version") },
    @{ Name = "rg"; Args = @("--version") },
    @{ Name = "fd"; Args = @("--version") },
    @{ Name = "deno"; Args = @("--version") },
    @{ Name = "node"; Args = @("--version") },
    @{ Name = "npm"; Args = @("--version") },
    @{ Name = "cargo"; Args = @("--version") },
    @{ Name = "tree-sitter"; Args = @("--version") },
    @{ Name = "lazygitrs"; Args = @("--version") },
    @{ Name = "yazi"; Args = @("--version") },
    @{ Name = "clang"; Args = @("--version") },
    @{ Name = "clangd"; Args = @("--version") },
    @{ Name = "7z"; Args = @("i") }
)

foreach ($check in $checks) {
    if (Test-Command $check.Name) {
        Write-Host ""
        Write-Host "[$($check.Name)]" -ForegroundColor Green
        & $check.Name @($check.Args) 2>&1 | Select-Object -First 8 | Out-Host
    }
    else {
        Write-Warning "$($check.Name) is not visible in the current shell yet."
    }
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "Windows Neovim bootstrap complete." -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Close and reopen Windows Terminal."
Write-Host "  2. In Windows Terminal: Settings -> Profiles -> PowerShell -> Appearance,"
Write-Host "     select 'JetBrainsMono Nerd Font' (or the registered JetBrains Nerd Font name)."
Write-Host "  3. Start Neovim and run :checkhealth"
Write-Host "  4. If your config uses Mason formatters/LSPs, run:"
Write-Host "     :MasonInstall stylua prettier biome black shfmt sql-formatter gopls lua-language-server texlab vale-ls"
Write-Host ""
Write-Host "Yazi notes:"
Write-Host "  - YAZI_FILE_ONE has been configured to Git for Windows' file.exe when available."
Write-Host "  - Keep the yazi.nvim realpath hook platform-aware in Lua:"
Write-Host '      resolve_relative_path_application = vim.fn.has("win32") == 1'
Write-Host '          and "C:/Program Files/Git/usr/bin/realpath.exe"'
Write-Host '          or "realpath"'
Write-Host ""
