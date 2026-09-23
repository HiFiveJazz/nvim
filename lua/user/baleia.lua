local M = {
  "m00qek/baleia.nvim",

  -- aerc explicitly sets this environment variable for its Neovim viewer.
  cond = function()
    return vim.env.AERC_NVIM_VIEWER == "1"
  end,

  -- Important: Baleia needs to be loaded before stdin is read.
  lazy = false,
}

M.config = function()
  local baleia = require("baleia").setup({
    strip_ansi_codes = true,
    async = false,
  })

  vim.g.baleia = baleia

  vim.api.nvim_create_user_command("BaleiaColorize", function()
    baleia.once(vim.api.nvim_get_current_buf())
  end, { bang = true })

  vim.api.nvim_create_user_command("BaleiaLogs", function()
    vim.cmd.messages()
  end, { bang = true })

  vim.api.nvim_create_autocmd("StdinReadPost", {
    once = true,
    callback = function(ev)
      -- Extra guard: only process stdin from the aerc viewer.
      if vim.env.AERC_NVIM_VIEWER ~= "1" then
        return
      end

      baleia.once(ev.buf)
      vim.bo[ev.buf].modified = false
    end,
  })
end

return M
