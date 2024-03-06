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
                "proto",
                "terraform",
                "bash",
                "regex",
                "markdown_inline"
            },
            auto_install = true,
            highlight = {
                enable = true,
            }
        })
    end
}
