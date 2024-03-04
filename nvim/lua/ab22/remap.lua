vim.g.mapleader = ' '
vim.keymap.set('n', '<leader>pv', vim.cmd.Ex)
vim.keymap.set({ 'n', 'v' }, 'y', '"+y')

vim.keymap.set('n', '<C-d>', '<C-d>zz')
vim.keymap.set('n', '<C-u>', '<C-u>zz')

vim.keymap.set('n', '<leader>b', vim.cmd.NvimTreeToggle)
vim.keymap.set('n', '<leader>t', vim.cmd.NvimTreeFocus)
vim.keymap.set('n', '<leader>gd', vim.cmd.DiffviewOpen)
