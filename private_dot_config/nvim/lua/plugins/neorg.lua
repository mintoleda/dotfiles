return {
  "nvim-neorg/neorg",
  lazy = false, -- Disable lazy loading as some `lazy.nvim` distributions set `lazy = true` by default
  version = "*", -- Pin Neorg to the latest stable release

  config = function()
    -- basic/default setup
    require("neorg").setup({
      load = {
        ["core.defaults"] = {}, -- sensible defaults
        ["core.concealer"] = {}, -- pretty icons/syntax sugars
        ["core.dirman"] = { -- workspace management
          config = {
            workspaces = {
              notes = "~/Notes", -- adjust path to your preferred notes dir
              school = "~/School/Notes/",
            },
            default_workspace = "notes",
          },
        },
      },
    })
  end,
}
