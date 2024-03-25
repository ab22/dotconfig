-- Golang format on save.
vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = "*.go",
    callback = function()
        require('go.format').goimport()
    end,
    group = vim.api.nvim_create_augroup("GoFormat", {}),
})

-- Format on save.
vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = "*.rs,*.tf,*.lua",
    callback = function()
        vim.lsp.buf.format()
    end,
    group = vim.api.nvim_create_augroup("FormatOnSave", {}),
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

-- Autoread files
vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "CursorHoldI", "FocusGained" }, {
    command = "if mode() != 'c' | checktime | endif",
    pattern = { "*" },
})
