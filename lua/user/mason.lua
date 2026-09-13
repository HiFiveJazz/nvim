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

  wk.add {
    {
      "<leader>lm",
      "<cmd>Mason<cr>",
      desc = "Mason Info",
      icon = { icon = " ", color = "blue" },
    },
  }

  require("mason").setup {
    ui = {
      border = "rounded",
    },

    -- registries = {
    --   "file:~/GitHub/mason-registry",
    -- },
  }

  require("mason-lspconfig").setup {
    ensure_installed = M.execs,

    -- rustaceanvim owns rust-analyzer.
    -- Keep it installed through Mason, but don't let
    -- mason-lspconfig start a second LSP client.
    automatic_enable = {
      exclude = {
        "rust_analyzer",
      },
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
end

return M
