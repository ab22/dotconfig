return {
    "folke/noice.nvim",
    event = "VeryLazy",
    opts = {},
    dependencies = {
        "MunifTanjim/nui.nvim",
        "rcarriga/nvim-notify",
    },
    config = function()
        vim.keymap.set('n', '<leader>nc', function()
            require("noice").cmd("dismiss")
        end)
        vim.keymap.set('n', '<leader>nh', function()
            require("noice").cmd("history")
        end)
        vim.keymap.set('n', '<leader>nl', function()
            require("noice").cmd("last")
        end)

        require("notify").setup({
            background_colour = "#000000",
        })
        require("noice").setup({
            lsp = {
                override = {
                    ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
                    ["vim.lsp.util.stylize_markdown"] = true,
                    ["cmp.entry.get_documentation"] = true, -- requires hrsh7th/nvim-cmp
                },
            },
            presets = {
                bottom_search = false,        -- use a classic bottom cmdline for search
                command_palette = true,       -- position the cmdline and popupmenu together
                long_message_to_split = true, -- long messages will be sent to a split
                inc_rename = false,           -- enables an input dialog for inc-rename.nvim
                lsp_doc_border = false,       -- add a border to hover docs and signature help
            },
        })

        require("telescope").load_extension("noice")
    end,
}
