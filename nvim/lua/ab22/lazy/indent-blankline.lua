return {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    opts = {},
    config = function()
        local ibl = require("ibl")
        local special_tab_char = false
        local indent_char = '▏'
        local cfg = {
            indent = {
                char = indent_char,
                tab_char = indent_char,
            },
            scope = {
                show_start = false,
                show_end = false
            }
        }

        ibl.setup(cfg)

        vim.keymap.set("n", "<leader>it", function()
            if special_tab_char then
                vim.opt.listchars:append { tab = nil, space = " " }
                cfg.indent.tab_char = indent_char
            else
                vim.opt.listchars:append { tab = '→ ', space = '·' }
                cfg.indent.tab_char = nil
            end

            ibl.setup(cfg)
            special_tab_char = not special_tab_char
        end)
    end
}
