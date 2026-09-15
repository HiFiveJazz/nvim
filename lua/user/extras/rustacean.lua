local M = {
  "mrcjkb/rustaceanvim",

  -- Pin to the current major release to avoid unexpected breaking changes.
  version = "^9",

  -- rustaceanvim implements its own filetype lazy-loading.
  -- Do not lazy-load it again through lazy.nvim.
  lazy = false,
}

function M.init()
  -- Using a function defers evaluating the configuration until
  -- rustaceanvim actually initializes for a Rust buffer.
  vim.g.rustaceanvim = function()
    local lspconfig = require "user.lspconfig"

    return {
      server = {
        on_attach = function(client, bufnr)
          lspconfig.on_attach(client, bufnr)
        end,

        capabilities = lspconfig.common_capabilities(),

        -- Disable rust-analyzer status notifications.
        status_notify_level = true,

        -- rust-analyzer configuration.
        default_settings = {
          ["rust-analyzer"] = {
            -- Embedded Rust example:
            --
            -- check = {
            --   allTargets = false,
            -- },
            --
            -- cargo = {
            --   target = "thumbv7em-none-eabihf",
            -- },

            checkOnSave = true,

            check = {
              command = "clippy",
            },

            lens = {
              enable = true,
            },

            inlayHints = {
              chainingHints = {
                enable = true,
              },

              parameterHints = {
                enable = true,
              },

              typeHints = {
                enable = true,
              },

              renderColons = true,
              maxLength = 25,

              lifetimeElisionHints = {
                enable = "skip_trivial",
                -- enable = "always",
                useParameterNames = true,
              },

              closureReturnTypeHints = {
                enable = "always",
              },

              discriminantHints = {
                enable = "always",
              },

              expressionAdjustmentHints = {
                enable = "always",
                mode = "prefix",
                hideOutsideUnsafe = true,
              },

              rangeExclusiveHints = {
                enable = true,
              },

              implicitDrops = {
                enable = true,
              },

              closingBraceHints = {
                enable = true,
                minLines = 25,
              },
            },
          },
        },
      },
    }
  end
end

return M
