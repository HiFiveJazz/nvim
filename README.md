# Dependencies

This project requires Neovim. Install via your preferred package manager.

***Arch Linux***

```sh
#Using Pacman
sudo pacman -S --noconfirm \
  git neovim python python-pip python-pynvim \
  wl-clipboard \
  deno npm \
  ripgrep fd \
  imagemagick \
  curl shfmt \
  yazi 7zip sshfs \
  tree-sitter-cli \
  gdb \
  rustup \
  noto-fonts-emoji ttf-jetbrains-mono-nerd
```


My configuration also comes with some languages that are installed via Mason, some of which require Npm. If you wish to use any of the languages I use, download Npm, otherwise remove the LSPs listed in the `lua/user/lspconfig.lua` file after installation. I also use `lazygitrs` for fast Git management. 

Install Npm via your preferred package manager.

```sh
#Using Pacman
sudo npm install -g neovim prettier
sudo pacman -S --noconfirm rustup
rustup update stable
cargo install stylua
cargo install lazygitrs
```


You're all done!

***macOS***

```sh
#Using Homebrew
brew install \
  git \
  neovim \
  python \
  deno \
  node \
  ripgrep \
  fd \
  imagemagick \
  curl \
  shfmt \
  yazi \
  sevenzip \
  tree-sitter-cli \
  gdb \

brew install --cask \
  font-jetbrains-mono-nerd-font \
  sshfs-mac
  rustup
```


My configuration also comes with some languages that are installed via Mason, some of which require Npm. If you wish to use any of the languages I use, download Npm, otherwise remove the LSPs listed in the `lua/user/lspconfig.lua` file after installation. I also use `lazygitrs` for fast Git management. 


```sh
#Using Homebrew
npm install -g neovim prettier
rustup default stable
cargo install stylua
cargo install lazygitrs
```

You're all done!

***Windows***

Run the included PowerShell setup script. This script includes
package dependencies and info about a couple Windows-specific
post-installation steps.

```powershell
#In Powershell
cd $env:LOCALAPPDATA
git clone https://github.com/HiFiveJazz/nvim
cd nvim
.\windows-setup.ps1
```

You're all done!
