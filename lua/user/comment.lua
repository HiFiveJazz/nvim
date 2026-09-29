local M = {
  "JoosepAlviste/nvim-ts-context-commentstring",
  event = { "BufReadPre", "BufNewFile" },
}

function M.config()
  require("ts_context_commentstring").setup({
    enable_autocmd = true,
  })
end

return M
