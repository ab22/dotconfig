return {
    "nvim-tree/nvim-tree.lua",
    version = "*",
    lazy = false,
    dependencies = {
        "nvim-tree/nvim-web-devicons",
    },
    config = function()
        local adaptive_width = true

        local function toggle_adaptive_width()
            adaptive_width = not adaptive_width
            require('nvim-tree.api').tree.reload()
        end

        local function get_max_view_width()
            return adaptive_width and -1 or 30
        end

        require("nvim-tree").setup {
            live_filter = {
                prefix = "[FILTER]: ",
                always_show_folders = false,
            },
            view = {
                width = {
                    min = 30,
                    max = get_max_view_width, -- Adaptive width.
                }
            },
            diagnostics = {
                enable = true,
            },
            git = {
                enable = true,
            },
            renderer = {
                highlight_git = "all",
                highlight_diagnostics = "all",
            },
            update_focused_file = {
                enable = true,
            },
            on_attach = function(bufnr)
                local api = require("nvim-tree.api")
                local function opts(desc)
                    return {
                        desc = "nvim-tree: " .. desc,
                        buffer = bufnr,
                        noremap = true,
                        silent = true,
                        nowait = true,
                    }
                end

                -- default mappings
                api.config.mappings.default_on_attach(bufnr)

                -- custom mappings
                vim.keymap.set('n', 'A', toggle_adaptive_width, opts('Toggle Adaptive Width'))

                -- open file upon creation
                api.events.subscribe(api.events.Event.FileCreated, function(file)
                    vim.cmd("edit " .. file.fname)
                end)
            end,
        }
    end
}
