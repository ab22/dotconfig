local format_golang_grp = vim.api.nvim_create_augroup("GoFormat", {})

vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = "*.go",
    callback = function()
        require('go.format').goimport()
    end,
    group = format_golang_grp,
})


local format_lua_grp = vim.api.nvim_create_augroup("LuaFormat", {})

vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = "*.lua",
    callback = function()
        vim.lsp.buf.format()
    end,
    group = format_golang_grp,
})

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
