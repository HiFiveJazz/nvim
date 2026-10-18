local M = {
  "brenton-leighton/multiple-cursors.nvim",
  version = "*",
  event = "VeryLazy",

  opts = {},

  keys = {
    -- Vertical cursors
    {
      "<M-j>",
      "<Cmd>MultipleCursorsAddDown<CR>",
      mode = { "n", "x" },
      desc = "Add cursor down",
    },
    {
      "<M-k>",
      "<Cmd>MultipleCursorsAddUp<CR>",
      mode = { "n", "x" },
      desc = "Add cursor up",
    },

    -- Tsoding-style occurrence selection
    {
      "<M-n>",
      "<Cmd>MultipleCursorsAddJumpNextMatch<CR>",
      mode = { "n", "x" },
      desc = "Add cursor and jump to next match",
    },
    {
      "<M-p>",
      "<Cmd>MultipleCursorsAddJumpPrevMatch<CR>",
      mode = { "n", "x" },
      desc = "Add cursor and jump to previous match",
    },

    -- Skip occurrence without adding it
    {
      "<M-s>",
      "<Cmd>MultipleCursorsJumpNextMatch<CR>",
      mode = { "n", "x" },
      desc = "Skip to next match",
    },

    -- Grab everything
    {
      "<M-a>",
      "<Cmd>MultipleCursorsAddMatches<CR>",
      mode = { "n", "x" },
      desc = "Add cursors to all matches",
    },

    -- Restrict matches to previous visual area
    {
      "<M-v>",
      "<Cmd>MultipleCursorsAddMatchesV<CR>",
      mode = { "n", "x" },
      desc = "Add matches in previous visual area",
    },
  },
}

return M
