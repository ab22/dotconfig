return {
    "sindrets/diffview.nvim",
    config = function()
        require("diffview").setup({
            file_panel = {
                win_config = {
                    win_opts = {
                        number = true,
                        statusline = 'DIFFVIEWFILES'
                    }
                }
            }
        })
    end
}
