return {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
        require('lualine').setup {
            options = {
                theme = 'catppuccin',
                disabled_filetypes = {
                    statusline = {
                        'NvimTree',
                        'DiffviewFiles',
                    },
                    winbar = {
                        'NvimTree',
                        'DiffviewFiles',
                    },
                },
            },
        }
    end
}
