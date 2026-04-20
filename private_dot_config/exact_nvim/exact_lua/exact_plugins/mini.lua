return {
  {
    'echasnovski/mini.nvim',
    config = function()
      require('mini.pairs').setup()
    end,
  },
  {
    'echasnovski/mini.animate',
    event = 'VeryLazy',
    config = function()
      local animate = require('mini.animate')
      animate.setup({
        cursor = {
          timing = animate.gen_timing.linear({ duration = 50, unit = 'total' }),
        },
        scroll = {
          timing = animate.gen_timing.linear({ duration = 120, unit = 'total' }),
          subscroll = animate.gen_subscroll.equal(),
        },
        resize = {
          timing = animate.gen_timing.linear({ duration = 80, unit = 'total' }),
        },
      })
    end,
  },
}
