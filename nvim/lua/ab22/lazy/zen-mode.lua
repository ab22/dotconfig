return {
    "folke/zen-mode.nvim",
    opts = {
        window = {
            width = .85,
            backdrop = 0.95
        },
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
