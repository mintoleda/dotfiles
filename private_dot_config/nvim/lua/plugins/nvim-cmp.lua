return {
  "hrsh7th/nvim-cmp",
  opts = function(_, opts)
    -- Import the nvim-cmp plugin
    local cmp = require("cmp")

    opts.mapping = vim.tbl_extend("force", opts.mapping, {

      -- Make <Tab> confirm the selected item
      ["<Tab>"] = cmp.mapping.confirm({ select = true }),

      -- Make <CR> (Enter) do nothing by removing its mapping
      -- This makes it fall back to the default behavior (inserting a newline)
      ["<CR>"] = nil,
    })

    return opts
  end,
}
