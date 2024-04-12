return {
    "sindrets/diffview.nvim",
    config = function()
        require("diffview").setup({
            file_panel = {
                win_config = {
                    win_opts = {
                        number = true,
                        statusline = 'DIFFVIEWFILES'
                    }
                }
            }
        })

        vim.keymap.set('n', '<leader>do', vim.cmd.DiffviewOpen)
        vim.keymap.set('n', '<leader>dc', vim.cmd.DiffviewClose)
    end
}
