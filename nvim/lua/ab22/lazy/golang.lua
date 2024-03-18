return {
    "ray-x/go.nvim",
    config = function()
        require("go").setup()

        vim.keymap.set('n', '<leader>gtn', function()
            vim.cmd('GoTest -vn')
        end)
        vim.keymap.set('n', '<leader>gta', function()
            vim.cmd('GoTest -v')
        end)
    end,
    event = { "CmdlineEnter" },
    ft = { "go", "gomod" },
    build = ':lua require("go.install").update_all_sync()',
}
