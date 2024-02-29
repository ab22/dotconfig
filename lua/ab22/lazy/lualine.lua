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
            sections = {
                lualine_a = { 'mode' },
                lualine_b = {
                    { 'filename', path = 1 }
                },
                lualine_c = { 'branch', 'diff', 'diagnostics' },
                lualine_x = { 'location', 'encoding', 'fileformat', 'filetype' },
                lualine_y = {},
                lualine_z = {},
            },
            inactive_sections = {
                lualine_a = { 'mode' },
                lualine_b = {
                    { 'filename', path = 1 }
                },
                lualine_c = { 'branch', 'diff', 'diagnostics' },
                lualine_x = { 'location', 'encoding', 'fileformat', 'filetype' },
                lualine_y = {},
                lualine_z = {},
            },
        }
    end
}
