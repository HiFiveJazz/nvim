local M = {
  "akinsho/toggleterm.nvim",
  event = "VeryLazy",
}

function M.config()
  local execs = {
    { nil, "<M-1>", "Horizontal Terminal", "horizontal", 0.3 },
    { nil, "<M-2>", "Vertical Terminal", "vertical", 0.4 },
    { nil, "<M-3>", "Float Terminal", "float", nil },
  }

  local function current_file_dir()
    return vim.fn.expand("%:p:h")
  end

  local function get_buf_size()
    local cbuf = vim.api.nvim_get_current_buf()
    local bufinfo = vim.tbl_filter(function(buf)
      return buf.bufnr == cbuf
    end, vim.fn.getwininfo(vim.api.nvim_get_current_win()))[1]

    if bufinfo == nil then
      return { width = -1, height = -1 }
    end

    return { width = bufinfo.width, height = bufinfo.height }
  end

  local function get_dynamic_terminal_size(direction, size)
    if direction ~= "float" and tostring(size):find(".", 1, true) then
      size = math.min(size, 1.0)
      local buf_sizes = get_buf_size()
      local buf_size = direction == "horizontal" and buf_sizes.height or buf_sizes.width
      return buf_size * size
    else
      return size
    end
  end

  local exec_toggle = function(opts)
    local Terminal = require("toggleterm.terminal").Terminal
    local term = Terminal:new({
      cmd = opts.cmd,
      count = opts.count,
      direction = opts.direction,
    })
    term:toggle(opts.size, opts.direction)
  end

  local add_exec = function(opts)
    local binary = opts.cmd:match("(%S+)")
    if vim.fn.executable(binary) ~= 1 then
      vim.notify("Skipping configuring executable " .. binary .. ". Please make sure it is installed properly.")
      return
    end

    vim.keymap.set({ "n", "t" }, opts.keymap, function()
      exec_toggle({
        cmd = opts.cmd,
        count = opts.count,
        direction = opts.direction,
        size = opts.size(),
      })
    end, { desc = opts.label, noremap = true, silent = true })
  end

  for i, exec in pairs(execs) do
    local direction = exec[4]

    local opts = {
      cmd = exec[1] or vim.o.shell,
      keymap = exec[2],
      label = exec[3],
      count = i + 100,
      direction = direction,
      size = function()
        return get_dynamic_terminal_size(direction, exec[5])
      end,
    }

    add_exec(opts)
  end

  require("toggleterm").setup({
    size = 20,
    open_mapping = [[<c-\>]],
    hide_numbers = true,
    shade_filetypes = {},
    shade_terminals = true,
    shading_factor = 2,
    start_in_insert = true,
    insert_mappings = true,
    persist_size = false,
    direction = "float",
    autochdir = false,
    close_on_exit = true,
    shell = nil,
    float_opts = {
      border = "rounded",
      winblend = 0,
      highlights = {
        border = "Normal",
        background = "Normal",
      },
    },
    winbar = {
      enabled = true,
      name_formatter = function(term)
        return term.count
      end,
    },
  })

  vim.cmd([[
    augroup terminal_setup | au!
    autocmd TermOpen * nnoremap <buffer><LeftRelease> <LeftRelease>i
    autocmd TermEnter * startinsert!
    augroup end
  ]])

  vim.api.nvim_create_autocmd("TermEnter", {
    pattern = "*",
    callback = function()
      vim.cmd("startinsert")
      _G.set_terminal_keymaps()
    end,
  })

  local opts = { noremap = true, silent = true }

  function _G.set_terminal_keymaps()
    vim.api.nvim_buf_set_keymap(0, "t", "<m-h>", [[<C-\><C-n><C-W>h]], opts)
    vim.api.nvim_buf_set_keymap(0, "t", "<m-j>", [[<C-\><C-n><C-W>j]], opts)
    vim.api.nvim_buf_set_keymap(0, "t", "<m-k>", [[<C-\><C-n><C-W>k]], opts)
    vim.api.nvim_buf_set_keymap(0, "t", "<m-l>", [[<C-\><C-n><C-W>l]], opts)
  end

  local Terminal = require("toggleterm.terminal").Terminal

  local function terminal_on_open(term)
    vim.cmd("startinsert!")
    vim.api.nvim_buf_set_keymap(term.bufnr, "n", "q", "<cmd>close<CR>", { noremap = true, silent = true })
  end

  local function terminal_on_close(_)
    vim.cmd("startinsert!")
  end

  local runners = {}

  local function current_file()
    return vim.api.nvim_buf_get_name(0)
  end

  local function project_root()
    local bufname = current_file()

    if vim.bo.filetype == "rust" then
      local cargo_root = vim.fs.root(bufname, { "Cargo.toml" })
      if cargo_root then
        return cargo_root
      end
    end

    local root = vim.fs.root(bufname, { "Makefile", ".git" })
    return root or vim.fn.getcwd()
  end

  local function git_root()
    local bufname = current_file()
    local root = vim.fs.root(bufname, { ".git" })
    return root or project_root()
  end

  -- local lazygit = Terminal:new({
  --   cmd = "lazygit",
  --   dir = function()
  --     return project_root()
  --   end,
  --   direction = "float",
  --   close_on_exit = false,
  --   hidden = true,
  --   float_opts = {
  --     border = "rounded",
  --   },
  --   on_open = terminal_on_open,
  --   on_close = terminal_on_close,
  -- })

  local function current_file_rel()
    return vim.fn.expand("%:.")
  end

  local function current_file_abs()
    return vim.fn.expand("%:p")
  end

  local function current_file_name_no_ext()
    return vim.fn.expand("%:t:r")
  end

  local function has_cargo_project()
    return vim.fs.root(current_file(), { "Cargo.toml" }) ~= nil
  end

  local function cargo_bin_name()
    local root = project_root()
    local cmd = [[
      cargo metadata --no-deps --format-version 1 |
      sed -n 's/.*"targets":\[\(.*\)\].*/\1/p' |
      grep '"kind":\["bin"\]' |
      sed -n 's/.*"name":"\([^"]*\)".*/\1/p' |
      head -n 1
    ]]

    local result = vim.system({ "sh", "-c", cmd }, { cwd = root, text = true }):wait()
    if result.code ~= 0 then
      return ""
    end

    return vim.trim(result.stdout or "")
  end

  local function get_commands()
    local ft = vim.bo.filetype
    local file_rel = current_file_rel()
    local file_abs = current_file_abs()
    local bin = current_file_name_no_ext()
    local out = string.format(".build/%s", bin)
    local rsbench = vim.fn.expand("$HOME/.config/nvim/scripts/rsbench")
    local bench_runs = 800

    if ft == "rust" then
      if has_cargo_project() then
        local cargo_bin = cargo_bin_name()

        -- if cargo_bin == nil or cargo_bin == "" then
        --   vim.notify("Could not determine Cargo binary name.", vim.log.levels.ERROR)
        --   return nil
        -- end

        if cargo_bin == nil or cargo_bin == "" then
          return {
            build = "cargo +nightly build",
            run = "cargo +nightly test -- --nocapture",
            bench = "cargo +nightly test --release -- --nocapture",
          }
        end

        local release_bin = string.format("./target/release/%s", cargo_bin)

        return {
          build = "cargo +nightly build --release",
          run = string.format('cargo +nightly build --release && "%s"', release_bin),
          bench = string.format(
            'cargo +nightly build --release && "%s" %d "%s"',
            rsbench,
            bench_runs,
            release_bin
          ),
        }
      else
        return {
          build = string.format('mkdir -p .build && rustc "%s" -O -o "%s"', file_abs, out),
          run = string.format('mkdir -p .build && rustc "%s" -O -o "%s" && "%s"', file_abs, out, "./" .. out),
          bench = string.format(
            'mkdir -p .build && rustc "%s" -O -o "%s" && "%s" %d "%s"',
            file_abs,
            out,
            rsbench,
            bench_runs,
            "./" .. out
          ),
        }
      end
      elseif ft == "c" then
        local file_dir = current_file_dir()
        local out = string.format("%s/.build/%s", file_dir, bin)

        return {
          build = string.format('mkdir -p "%s/.build" && cc -O2 "%s" -o "%s"', file_dir, file_abs, out),
          run = string.format(
			'mkdir -p "%s/.build" && cc -O2 "%s" -o "%s" && "%s"',
            file_dir,
            file_abs,
            out,
            out
          ),
          bench = string.format(
            'mkdir -p "%s/.build" && cc -O2 "%s" -o "%s" && "%s" && hyperfine -N --warmup 5000 --min-runs 10000 "%s"',
            file_dir,
            file_abs,
            out,
            out,
            out
          ),
        }
      end
      -- elseif ft == "c" then
      --   return {
      --     build = string.format('mkdir -p .build && cc -O2 "%s" -o "%s"', file_abs, out),
      --     run = string.format('mkdir -p .build && cc -O2 "%s" -o "%s" && "./%s"', file_abs, out, out),
      --     bench = string.format(
      --       'mkdir -p .build && cc -O2 "%s" -o "%s" && "./%s" && hyperfine -N --warmup 5000 --min-runs 10000 "./%s"',
      --       file_abs,
      --       out,
      --       out,
      --       out
      --     ),
      --   }
      -- end

    return nil
  end

  local function get_runner(action)
    local commands = get_commands()
    if not commands or not commands[action] then
      vim.notify("No " .. action .. " command configured for filetype: " .. vim.bo.filetype, vim.log.levels.WARN)
      return nil
    end

    local root = project_root()
    local key = root .. "::" .. vim.bo.filetype .. "::" .. action

    if not runners[key] then
      runners[key] = Terminal:new({
        cmd = commands[action],
        dir = root,
        direction = "float",
        close_on_exit = false,
        hidden = true,
        float_opts = {
          border = "rounded",
        },
        on_open = terminal_on_open,
        on_close = terminal_on_close,
      })
    else
      runners[key].cmd = commands[action]
      runners[key].dir = root
    end

    return runners[key]
  end

  local function generic_build()
    local term = get_runner("build")
    if term then
      term:toggle()
    end
  end

  local function generic_run()
    local term = get_runner("run")
    if term then
      term:toggle()
    end
  end

  local function generic_bench()
    local term = get_runner("bench")
    if term then
      term:toggle()
    end
  end

  function _lazygit_toggle()
    local term = Terminal:new({
      cmd = "lazygitrs",
      dir = git_root(),
      direction = "float",
      close_on_exit = true,
      hidden = true,
      float_opts = {
        border = "rounded",
      },
      on_open = terminal_on_open,
      on_close = terminal_on_close,
    })

    term:toggle()
  end

  function _generic_build()
    generic_build()
  end

  function _generic_run()
    generic_run()
  end

  function _generic_bench()
    generic_bench()
  end

  local wk = require("which-key")

  wk.add({
    { "<leader>lg", _lazygit_toggle, desc = "Lazy Git", icon = { icon = " ", color = "blue" } },
    { "<leader>cb", _generic_build, desc = "Build", icon = { icon = " ", color = "green" } },
    { "<leader>cr", _generic_run, desc = "Run", icon = { icon = "󰓅 ", color = "green" } },
    { "<leader>ct", _generic_bench, desc = "Benchmark", icon = { icon = "󱎫 ", color = "green" } },
  })
end

return M
