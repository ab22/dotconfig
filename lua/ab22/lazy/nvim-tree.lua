return {
    "nvim-tree/nvim-tree.lua",
    version = "*",
    lazy = false,
    dependencies = {
        "nvim-tree/nvim-web-devicons",
    },
    config = function()
        require("nvim-tree").setup {
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
            }
        }
    end
}
