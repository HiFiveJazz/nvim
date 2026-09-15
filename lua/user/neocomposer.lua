local M = {
  "HiFiveJazz/NeoComposer.nvim",
  -- dir = "~/GitHub/NeoComposer.nvim/",
  -- "ecthelionvi/NeoComposer.nvim",
  dependencies = {
    "kkharji/sqlite.lua",
    "nvim-telescope/telescope.nvim",
  },
  event = "VeryLazy",
}

function M.config()
  if vim.fn.has("win32") == 1 then
     vim.g.sqlite_clib_path =
	 (vim.fn.stdpath("data") .. "/sqlite/sqlite3.dll"):gsub("\\", "/")
  end

  require("NeoComposer").setup({
    notify = true,
    delay_timer = 150,
    queue_most_recent = true,
    window = {
      width = 60,
      height = 10,
      border = "rounded",
      winhl = {
        Normal = "ComposerNormal",
      },
    },
    colors = {
      bg = "#000000", -- Transparent Macro Menu
      -- status_bg = "#999123",
      -- fg = "#ff9e64",
      -- red = "#ec5f67",
      -- blue = "#5fb3b3",
      -- green = "#99c794",
    },
    keymaps = {
      toggle_macro_menu = "mm",
      toggle_record = "mr",
      play_macro = "mp",
      stop_macro = "ms",
    },
  })
  -- vim.keymap.set("n", "m", "<Nop>", { silent = true })

  -- Custom highlight groups for LUALINE ONLY
  -- (Background matches lualine_c_normal: #16161e)
  vim.api.nvim_set_hl(0, "NCRecSymbol",   { fg = "#ec5f67", bg = "#16161e" }) -- red dot
  vim.api.nvim_set_hl(0, "NCRecText",     { fg = "#a9b1d6", bg = "#16161e" }) -- orange REC
  vim.api.nvim_set_hl(0, "NCPlaySymbol",  { fg = "#99c794", bg = "#16161e" }) -- green ▶
  vim.api.nvim_set_hl(0, "NCPlayText",    { fg = "#a9b1d6", bg = "#16161e" }) -- normal PLAY text
  vim.api.nvim_set_hl(0, "NCDelaySymbol", { fg = "#5fb3b3", bg = "#16161e" }) -- cyan ⏱
  vim.api.nvim_set_hl(0, "NCDelayText",   { fg = "#a9b1d6", bg = "#16161e" }) -- normal DELAY text


  -- Monkey patch status function
  -- Replaces NeoComposer's baked-in highlight groups
  local ui = require("NeoComposer.ui")
  local state = require("NeoComposer.state")

  ui.status_recording = function()
    local status = ""

    if state.get_recording() then
      status = "%#NCRecSymbol#●%* %#NCRecText#REC%*"
    elseif state.get_playing() then
      status = "%#NCPlaySymbol#▶%* %#NCPlayText#PLAY%*"
    end

    if state.get_delay() then
      local delay_part = "%#NCDelaySymbol#⏱%* %#NCDelayText#DELAY%*"
      status = (status == "" and delay_part) or (status .. " " .. delay_part)
    end

    return status


  end

  local wk = require("which-key")
  wk.add({
    { "m", group = "Macros", icon = { icon = "󱚣 ", color = "green", }, },
    { "mm", desc = "Macro Menu", icon = { icon = " ", color = "azure", }, },
    { "mr", desc = "Toggle Recording Macro", icon = { icon = "● ", color = "red", }, },
    { "mp", desc = "Play Macro", icon = { icon = " ", color = "green", }, },
    { "ms", desc = "Stop Macro", icon = { icon = " ", color = "grey", }, },
  })
end

return M
