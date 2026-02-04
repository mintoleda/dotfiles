return {
  {
    "folke/snacks.nvim",
    keys = {
      -- Override <leader>e to open Explorer in the Current Working Directory (cwd)
      {
        "<leader>e",
        function()
          Snacks.explorer({ cwd = vim.fn.getcwd() })
        end,
        desc = "Explorer Snacks (cwd)",
      },
    },
  },
}
