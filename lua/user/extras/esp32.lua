local M = {
  "Aietes/esp32.nvim",
  lazy = false,
  dependencies = {
    "folke/snacks.nvim",
  },
}

function M.config()
  require("esp32").setup({
    build_dir = "build.clang",
  })

  vim.lsp.config("clangd", require("esp32").lsp_config())
  vim.lsp.enable("clangd")
end

return M
