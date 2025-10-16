return {
  -- Install Everforest
  {
    "sainnhe/everforest",
    lazy = false,
    priority = 1000, -- load before other UI plugins
    init = function()
      vim.g.everforest_background = "dark"
      vim.g.everforest_enable_italic = 1
      vim.g.everforest_better_performance = 1
    end,
  },

  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "everforest",
    },
  },
}
