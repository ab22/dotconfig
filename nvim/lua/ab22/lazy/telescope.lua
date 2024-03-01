return {
    "nvim-telescope/telescope.nvim",

    tag = "0.1.5",

    dependencies = {
        "nvim-lua/plenary.nvim"
    },

    config = function()
        require('telescope').setup({})

        local builtin = require('telescope.builtin')
        vim.keymap.set('n', '<leader>pf', builtin.find_files, {})
        vim.keymap.set('n', '<C-p>', builtin.git_files, {})
        vim.keymap.set('n', '<leader>pws', function()
            local word = vim.fn.expand("<cword>")
            builtin.grep_string({ search = word })
        end)
        vim.keymap.set('n', '<leader>pWs', function()
            local word = vim.fn.expand("<cWORD>")
            builtin.grep_string({ search = word })
        end)
        vim.keymap.set('n', '<leader>ps', function()
            builtin.grep_string({ search = vim.fn.input("Grep > ") })
        end)
        --
        -- LSP
        --
        vim.keymap.set('n', '<leader>vh', builtin.help_tags, {})
        vim.keymap.set('n', 'gd', builtin.lsp_definitions, {})
        vim.keymap.set('n', 'gi', builtin.lsp_implementations, {})
        vim.keymap.set('n', 'gr', builtin.lsp_references, {})
        vim.keymap.set('n', '<leader>D', builtin.lsp_type_definitions, {})
        vim.keymap.set('n', 'gic', builtin.lsp_incoming_calls, {})
        vim.keymap.set('n', 'goc', builtin.lsp_outgoing_calls, {})

        --
        -- Vim
        --
        vim.keymap.set('n', '<leader>cs', builtin.colorscheme, {})
    end
}
