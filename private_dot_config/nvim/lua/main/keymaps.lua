-- set <space> as the leader key
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- disable space's default behavior in normal and visual
vim.keymap.set({'n', 'v' }, '<Space>', '<Nop>', {silent = true })

-- simplicity
local opts = {noremap = true, silent = true}

-- delete char w/o yanking
vim.keymap.set('n', 'x', '"_x', opts)

-- vertical scroll and center
vim.keymap.set('n', '<C-d>', '<C-d>zz', opts)
vim.keymap.set('n', '<C-u>', '<C-u>zz', opts)

-- tabs
-- vim.keymap.set('n', '<leader>to', ':tabnew<CR>', opts) -- open new
vim.keymap.set('n', '<leader>tx', ':tabclose<CR>', opts) -- close current
-- vim.keymap.set('n', '<leader>tn', ':tabn<CR>', opts) -- go to next
-- vim.keymap.set('n', '<leader>tp', ':tabp<CR>', opts) -- go to prev

-- buffers
vim.keymap.set('n', '<Tab>', ':bnext<CR>', opts)
vim.keymap.set('n', '<S-Tab>', ':bprevious<CR>', opts)
vim.keymap.set('n', '<leader>bd', ':bdelete!<CR>', opts) -- close buffer
-- vim.keymap.set('n', '<leader>b', '<cmd> enew <CR>', opts) -- new buffer

-- stay in indent mode
vim.keymap.set('v', '<', '<gv',opts)
vim.keymap.set('v', '>', '>gv', opts)

-- keep last yanked after paste
vim.keymap.set('v', 'p', '"_dP', opts)
