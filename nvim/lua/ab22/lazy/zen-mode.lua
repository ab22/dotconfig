return {
    "folke/zen-mode.nvim",
    opts = {
        plugins = {
            options = {
                enabled = true,
                ruler = false,
                showcmd = false,
                laststatus = 3,
            },
            tmux = {
                enabled = false,
            },
        },
    },
    config = function()
        vim.keymap.set('n', '<leader>gz', vim.cmd.ZenMode)
    end
}
