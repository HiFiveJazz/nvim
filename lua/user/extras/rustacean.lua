local M = {
  "mrcjkb/rustaceanvim",
  -- version = "^6",
  ft = { "rust" },
}

function M.config()
  local lspconfig = require "user.lspconfig"

  vim.g.rustaceanvim = {
    tools = {},
    server = {

      -- cmd = { "rustup", "run", "nightly", "rust-analyzer" },
      on_attach = function(client, bufnr)
        -- your global LSP setup (keymaps, etc.)
        lspconfig.on_attach(client, bufnr)
        -- enable native inlay hints (new API: enable(boolean, {bufnr=...}))
        -- pcall(vim.lsp.inlay_hint.enable, true, { bufnr = bufnr })

      end,

      capabilities = lspconfig.common_capabilities(),

      -- 🔇 disable rust-analyzer status popups (e.g. workspace discovery)
      status_notify_level = false,  -- same as require("rustaceanvim").disable

      settings = {
        ["rust-analyzer"] = {
          -- -- BEGIN: MICROBIT RUST SETTINGS
          -- check = {
          --   allTargets = false, -- Avoid checking all targets
          -- },
          -- cargo = {
          --   target = "thumbv7em-none-eabihf", -- Set embedded Rust target
          -- },
          -- -- END: MICROBIT RUST SETTINGS
          -- run checks on save; choose command via `check.command`
          checkOnSave = true,
          check = { command = "clippy" }, -- or "check"

          lens = { enable = true },

          -- FLAT inlayHints schema (so hints actually render)
          inlayHints = {
            enable = true,
            -- core toggles
            chainingHints  = true,
            parameterHints = true,
            typeHints      = true,
            -- fine-tuning
            renderColons   = true,
            maxLength      = 25,
            lifetimeElisionHints       = { enable = "always", useParameterNames = true },
            closureReturnTypeHints     = { enable = "always" },
            discriminantHints          = { enable = "always" },
            expressionAdjustmentHints  = { mode = "prefix", hideOutsideUnsafe = false },
            rangeExclusiveHints        = true,
            implicitDrops              = { enable = true },
            closingBraceHints          = { enable = true, minLines = 25 },
          },
        },
      },
    },
    -- DAP configuration
    -- dap = {},
  }
end

return M
