local M = {
  "mikavilpas/yazi.nvim",
  version = "*",
  event = "VeryLazy",
  dependencies = {
    { "nvim-lua/plenary.nvim", lazy = true },
  },
keys = {
    {
      "<leader>e",
      mode = { "n", "v" },
      function()
        -- vim.cmd("Yazi cwd")
        vim.cmd("Yazi")
      end,
      desc = "File Explorer",
    },
  },
}

function M.init()
  vim.g.loaded_netrw = 1
  vim.g.loaded_netrwPlugin = 1
  vim.g.loaded_netrwSettings = 1
  vim.g.loaded_netrwFileHandlers = 1
end

function M.config()
  require("yazi").setup({
    open_for_directories = true,

    open_multiple_tabs = false,
    change_neovim_cwd_on_close = false,

    floating_window_scaling_factor = 0.90,
    yazi_floating_window_winblend = 0,
    yazi_floating_window_border = "rounded",
    yazi_floating_window_zindex = nil,

    log_level = vim.log.levels.OFF,

    hooks = {
      resolve_relative_path_application = vim.fn.has("win32") == 1
          and "C:/Program Files/Git/usr/bin/realpath.exe"
          or "realpath",
    },

    keymaps = {
      show_help = "<f1>",
      open_file_in_vertical_split = "<c-v>",
      open_file_in_horizontal_split = "<c-x>",
      open_file_in_tab = "<c-t>",
      grep_in_directory = "<c-s>",
      replace_in_directory = "<c-g>",
      cycle_open_buffers = "<tab>",
      copy_relative_path_to_selected_files = "<c-y>",
      send_to_quickfix_list = "<c-q>",
    },

    clipboard_register = "*",

    highlight_hovered_buffers_in_same_directory = true,

    integrations = {
      bufdelete_implementation = "bundled-snacks",
    },

    future_features = {
      use_cwd_file = true,
      new_shell_escaping = true,
    },
  })
end

return M
