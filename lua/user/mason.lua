local M = {
  "mason-org/mason-lspconfig.nvim",
  dependencies = {
    "neovim/nvim-lspconfig",
    "mason-org/mason.nvim",
    "nvim-lua/plenary.nvim",
  },
}

M.execs = {
  "cssls",
  "html",
  "pyright",
  "bashls",
  "jsonls",
  "rust_analyzer",
  -- "ltex",
  -- "texlab",
}

function M.config()
  local wk = require "which-key"
  wk.add{
    { "<leader>lm", "<cmd>Mason<cr>", desc = "Mason Info", icon = { icon = " ", color = "blue"}},
  }

  require("mason").setup {
  -- registries = {
  --     "file:~/GitHub/mason-registry",
  --   },
    ui = {
      border = "rounded",
    },
  }
  vim.lsp.config("armls", {
    cmd = { "armls" },
    filetypes = { "asm" },

    settings = {
      armls = {
        diagnostics = {
          enable = true,
          disableCategories = {
            -- "invalidOperand",
            -- "tooManyOperands",
            -- "tooFewOperands",
          },
        },
      },
    },
  })

vim.lsp.enable("armls")
  require("mason-lspconfig").setup {
    ensure_installed = M.execs,
  }
end

return M
