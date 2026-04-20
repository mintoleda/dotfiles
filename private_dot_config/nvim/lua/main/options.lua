vim.wo.number = true

-- sync cliboard w/ os
vim.schedule(function()
	vim.o.clipboard = "unnamedplus"
end)

vim.o.wrap = false
vim.o.linebreak = true
vim.o.mouse = "a"
vim.o.autoindent = true
vim.o.shiftwidth = 4
vim.o.tabstop = 4
vim.o.softtabstop = 4
vim.o.expandtab = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.opt.textwidth = 100
