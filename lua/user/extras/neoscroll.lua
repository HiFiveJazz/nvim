local M = {
  "karb94/neoscroll.nvim",
  commit = "e786577",
  dependencies = {
    "folke/which-key.nvim",
  },
}

function M.config()
  require("neoscroll").setup({
    mappings = {}, -- we will define our own mappings
    hide_cursor = true,
    stop_eof = true,
    respect_scrolloff = false,
    cursor_scrolls_alone = true,
    easing_function = nil,
    performance_mode = false,
  })

  local neoscroll = require("neoscroll")

  -- Define scroll behavior
  local scroll_down = function()
    neoscroll.scroll(vim.wo.scroll, true, 250)
  end

  local scroll_up = function()
    neoscroll.scroll(-vim.wo.scroll, true, 250)
  end

  -- Keymaps
  vim.keymap.set({ "n", "v" }, "<C-j>", scroll_down, { desc = "Scroll Down (Smooth)" })
  vim.keymap.set({ "n", "v" }, "<C-k>", scroll_up,   { desc = "Scroll Up (Smooth)" })
end

return M
