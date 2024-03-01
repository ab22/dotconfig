-- Golang format on save.
vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = "*.go",
    callback = function()
        require('go.format').goimport()
    end,
    group = vim.api.nvim_create_augroup("GoFormat", {}),
})

-- Lua format on save.
vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = "*.lua",
    callback = function()
        vim.lsp.buf.format()
    end,
    group = vim.api.nvim_create_augroup("LuaFormat", {}),
})

-- Open nvim-tree automatically if we load a directory instead of a file.
vim.api.nvim_create_autocmd({ "VimEnter" }, {
    callback = function(data)
        local directory = vim.fn.isdirectory(data.file) == 1

        if not directory then
            return
        end

        -- Change to the directory
        vim.cmd.cd(data.file)

        -- Open the tree
        require("nvim-tree.api").tree.open()
    end
})
