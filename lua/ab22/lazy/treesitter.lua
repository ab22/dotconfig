return {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
        require("nvim-treesitter.configs").setup({
            ensure_installed = {
                "vimdoc",
                "javascript",
                "typescript",
                "c",
                "lua",
                "rust",
                "go",
                "json",
                "bash",
            },
            auto_install = true,
            highlight = {
                enable = true,
            }
        })
    end
}
