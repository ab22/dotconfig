return {
    'romgrk/barbar.nvim',
    dependencies = {
        'nvim-tree/nvim-web-devicons',
    },
    init = function()
        vim.g.barbar_auto_setup = false
    end,
    config = function()
        require('barbar').setup({
            sidebar_filetypes = {
                NvimTree = true,
                undotree = true,
                DiffviewFiles = true,
            }
        })

        vim.keymap.set('n', '<leader>tn', '<Cmd>BufferNext<CR>')
        vim.keymap.set('n', '<leader>tp', '<Cmd>BufferPrevious<CR>')
        vim.keymap.set('n', '<leader>tc', '<Cmd>BufferClose<CR>')
        vim.keymap.set('n', '<leader>toc', '<Cmd>BufferCloseAllButCurrent<CR>')
        vim.keymap.set('n', '<leader>tuc', '<Cmd>BufferCloseAllButPinned<CR>')
        vim.keymap.set('n', '<leader>tlc', '<Cmd>BufferCloseBuffersLeft<CR>')
        vim.keymap.set('n', '<leader>trc', '<Cmd>BufferCloseBuffersRight<CR>')
        vim.keymap.set('n', '<leader>tP', '<Cmd>BufferPin<CR>')

        vim.keymap.set('n', '<leader>t1', '<Cmd>BufferGoto 1<CR>')
        vim.keymap.set('n', '<leader>t2', '<Cmd>BufferGoto 2<CR>')
        vim.keymap.set('n', '<leader>t3', '<Cmd>BufferGoto 3<CR>')
        vim.keymap.set('n', '<leader>t4', '<Cmd>BufferGoto 4<CR>')
        vim.keymap.set('n', '<leader>t5', '<Cmd>BufferGoto 5<CR>')
        vim.keymap.set('n', '<leader>t6', '<Cmd>BufferGoto 6<CR>')
        vim.keymap.set('n', '<leader>t7', '<Cmd>BufferGoto 7<CR>')
        vim.keymap.set('n', '<leader>t8', '<Cmd>BufferGoto 8<CR>')
        vim.keymap.set('n', '<leader>t9', '<Cmd>BufferGoto 9<CR>')
    end,
    version = "^1.0.0",
}
