return {
    "folke/trouble.nvim",
    dependencies = {
        "nvim-tree/nvim-web-devicons",
    },
    opts = {
        height = 20,
    },
    config = function()
        vim.keymap.set("n", "<leader>xx", function()
            require("trouble").toggle()
        end)
        vim.keymap.set("n", "<leader>xl", function()
            require("trouble").toggle("loclist")
        end)
        vim.keymap.set("n", "<leader>xr", function()
            require("trouble").toggle("lsp_references")
        end)
    end
}
