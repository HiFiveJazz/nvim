local M = {
  "nvimtools/none-ls.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
}

function M.config()
  local null_ls = require("null-ls")

  null_ls.setup({
    debug = false, -- flip to true only when debugging
    sources = {
      -- Lua
      null_ls.builtins.formatting.stylua,

      -- Web
      null_ls.builtins.formatting.prettier,
      null_ls.builtins.formatting.biome,

      -- Python
      null_ls.builtins.formatting.black,

      -- Shell
      null_ls.builtins.formatting.shfmt,
      -- null_ls.builtins.diagnostics.shellcheck,

      -- SQL
      null_ls.builtins.formatting.sql_formatter,

      -- Completion
      null_ls.builtins.completion.spell,
    },
  })
end

return M

