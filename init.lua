-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--branch=stable",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- ===== Options =====
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.mouse = "a"
vim.opt.clipboard = "unnamedplus"
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"
vim.opt.completeopt = { "menu", "menuone", "noselect" }
vim.opt.undofile = true
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.inccommand = "split"
vim.opt.timeoutlen = 300

-- PEP8: 4-space indent for Python
vim.api.nvim_create_autocmd("FileType", {
  pattern = "python",
  callback = function()
    vim.bo.tabstop = 4
    vim.bo.shiftwidth = 4
  end,
})

vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })

vim.cmd.colorscheme("bloomberg")

-- ===== General keymaps =====
vim.keymap.set("n", "\\", "<cmd>Neotree toggle<CR>", { desc = "Toggle file tree" })
vim.keymap.set("n", "<leader>f", function()
  require("conform").format()
end, { desc = "Format buffer" })

-- ===== LSP keymaps =====
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(event)
    local map = function(keys, func, desc)
      vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
    end
    map("gd", vim.lsp.buf.definition, "Goto definition")
    map("gD", vim.lsp.buf.declaration, "Goto declaration")
    map("gi", vim.lsp.buf.implementation, "Goto implementation")
    map("gr", vim.lsp.buf.references, "References")
    map("K", vim.lsp.buf.hover, "Hover")
    map("<C-k>", vim.lsp.buf.signature_help, "Signature help")
    map("<leader>rn", vim.lsp.buf.rename, "Rename")
    map("<leader>ca", vim.lsp.buf.code_action, "Code action")
    map("<leader>ws", vim.lsp.buf.workspace_symbol, "Workspace symbols")
  end,
})

-- Diagnostics
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous diagnostic" })
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Diagnostic float" })
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Diagnostics to loclist" })

-- ===== Plugins =====
require("lazy").setup({
  -- Completion
  {
    "saghen/blink.cmp",
    version = "*",
    dependencies = { "rafamadriz/friendly-snippets" },
    opts = {
      keymap = { preset = "super-tab" },
      completion = { documentation = { auto_show = true } },
    },
  },
  { "hrsh7th/nvim-cmp", enabled = false },

  -- Formatting
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        javascript = { "prettier" },
        typescript = { "prettier" },
        javascriptreact = { "prettier" },
        typescriptreact = { "prettier" },
        vue = { "prettier" },
        json = { "prettier" },
        jsonc = { "prettier" },
        html = { "prettier" },
        css = { "prettier" },
        scss = { "prettier" },
        less = { "prettier" },
        yaml = { "prettier" },
        markdown = { "prettier" },
        graphql = { "prettier" },
        sh = { "shfmt" },
        python = { "ruff_format" },
      },
      format_on_save = { timeout_ms = 500, lsp_fallback = false },
    },
  },

  -- File tree
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    opts = {
      filesystem = {
        filtered_items = { visible = true },
      },
      window = { width = 32 },
    },
  },

  -- Finder
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = "Telescope",
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<CR>", desc = "Find files" },
      { "<leader>fg", "<cmd>Telescope live_grep<CR>", desc = "Live grep" },
      { "<leader>fb", "<cmd>Telescope buffers<CR>", desc = "Buffers" },
      { "<leader>fh", "<cmd>Telescope help_tags<CR>", desc = "Help tags" },
      { "<leader>fd", "<cmd>Telescope diagnostics<CR>", desc = "Diagnostics" },
      { "<leader>fs", "<cmd>Telescope lsp_document_symbols<CR>", desc = "Document symbols" },
    },
    opts = {
      defaults = {
        file_ignore_patterns = { "node_modules", ".git", "%.lock" },
      },
    },
  },

  -- Git
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      on_attach = function(bufnr)
        local gs = require("gitsigns")
        local function map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
        end
        map("n", "]h", gs.next_hunk, "Next hunk")
        map("n", "[h", gs.prev_hunk, "Prev hunk")
        map("n", "<leader>gb", gs.blame_line, "Blame line")
        map("n", "<leader>gp", gs.preview_hunk, "Preview hunk")
        map("n", "<leader>gr", gs.reset_hunk, "Reset hunk")
        map("n", "<leader>gR", gs.reset_buffer, "Reset buffer")
        map("n", "<leader>gS", gs.stage_buffer, "Stage buffer")
      end,
    },
  },

  -- Comments, pairs, textobjects, surround
  { "echasnovski/mini.comment", event = "VeryLazy", opts = {} },
  { "echasnovski/mini.pairs", event = { "InsertEnter", "CmdlineEnter" }, opts = {} },
  { "echasnovski/mini.ai", event = "VeryLazy", opts = {} },
  { "echasnovski/mini.surround", event = "VeryLazy", opts = {} },

  -- Statusline
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = { options = { theme = "auto" } },
  },

  -- Keymap hints
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    keys = {
      { "<leader>?", function() require("which-key").show() end, desc = "Show keymaps" },
    },
    opts = {},
  },

  -- Syntax
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    opts = {
      ensure_installed = {
        "lua",
        "javascript",
        "typescript",
        "tsx",
        "html",
        "css",
        "json",
        "yaml",
        "markdown",
        "markdown_inline",
        "bash",
        "python",
        "java",
      },
      highlight = { enable = true },
      indent = { enable = true },
    },
  },

  -- Live markdown rendering in-buffer
  {
    "OXY2DEV/markview.nvim",
    ft = "markdown",
    opts = {},
  },

  -- Rendered previews inside the terminal (kitty graphics protocol)
  {
    "3rd/image.nvim",
    lazy = true,
    opts = {},
  },

  -- LSP installers
  { "williamboman/mason.nvim", opts = {} },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    opts = {
      ensure_installed = {
        "lua-language-server",
        "typescript-language-server",
        "vue-language-server",
        "pyright",
        "html-lsp",
        "css-lsp",
        "json-lsp",
        "bash-language-server",
        "jdtls",
        "ruff",
        "prettier",
        "stylua",
        "shfmt",
      },
    },
  },
})

-- ===== LSP servers =====
local servers = {
  lua_ls = { cmd = { "lua-language-server" }, filetypes = { "lua" } },
  ts_ls = {
    cmd = { "typescript-language-server", "--stdio" },
    filetypes = { "typescript", "javascript", "typescriptreact", "javascriptreact" },
  },
  volar = { cmd = { "vue-language-server", "--stdio" }, filetypes = { "vue" } },
  pyright = { cmd = { "pyright-langserver", "--stdio" }, filetypes = { "python" } },
  html = { cmd = { "vscode-html-language-server", "--stdio" }, filetypes = { "html" } },
  cssls = { cmd = { "vscode-css-language-server", "--stdio" }, filetypes = { "css", "scss", "less" } },
  jsonls = { cmd = { "vscode-json-language-server", "--stdio" }, filetypes = { "json", "jsonc" } },
  bashls = { cmd = { "bash-language-server", "start" }, filetypes = { "sh", "bash" } },
  jdtls = {
    cmd = { "jdtls", "-data", vim.fn.stdpath("cache") .. "/jdtls-workspace" },
    filetypes = { "java" },
  },
  ruff = { cmd = { "ruff", "server" }, filetypes = { "python" } },
}
for name, cfg in pairs(servers) do
  vim.lsp.config(name, cfg)
  vim.lsp.enable(name)
end

-- Live markdown previews (pdf / slides / html / docx / pptx)
require("mdpreview")
