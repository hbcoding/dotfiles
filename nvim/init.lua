-- ============================================================
-- Basic settings
-- ============================================================
vim.opt.number = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.smartindent = true
vim.opt.wrap = true
vim.opt.linebreak = true
vim.opt.breakindent = true
vim.opt.spell = true
vim.opt.spelllang = { "en_us" }
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"
vim.opt.mouse = "a"
vim.opt.clipboard = "unnamedplus"
vim.g.mapleader = " "

-- Enable Treesitter-based folding
vim.opt.foldmethod = "expr"
vim.opt.foldexpr   = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldenable = false

-- ============================================================
-- Environment for Digestif (paths to ConTeXt LMTX macro sources)
-- ============================================================
vim.env.DIGESTIF_TEXMF = table.concat({
  vim.fn.expand("~/context/tex/texmf-context"),
  vim.fn.expand("~/context/tex/texmf"),
  vim.fn.expand("~/context/tex/texmf-modules"),
}, ":")

-- ============================================================
-- Recognise ConTeXt filetypes
-- ============================================================
vim.filetype.add({
  extension = {
    mkiv = "context",
    mkxl = "context",
    mkvi = "context",
    mklx = "context",
  },
  pattern = {
    [".*%.tex"] = function() return "context" end,
  },
})

-- ============================================================
-- Bootstrap lazy.nvim
-- ============================================================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- ============================================================
-- Plugins
-- ============================================================
require("lazy").setup({
  -- LSP
  { "neovim/nvim-lspconfig" },

  -- Treesitter (main branch API)
  { "nvim-treesitter/nvim-treesitter",
    branch = "main",
    build  = ":TSUpdate",
    lazy   = false,
    config = function()
      vim.treesitter.language.register("latex", "context")

      vim.api.nvim_create_autocmd("FileType", {
        pattern = {
          "tex", "plaintex", "context", "bib", "bibtex",
          "lua", "vim", "markdown",
        },
        callback = function(args)
          local ft = vim.bo[args.buf].filetype
          local lang = vim.treesitter.language.get_lang(ft) or ft
          pcall(function()
            vim.treesitter.language.add(lang)
            vim.treesitter.start(args.buf, lang)
          end)
        end,
      })
    end,
  },

  -- Snippet engine + starter snippet library
  { "L3MON4D3/LuaSnip",
    lazy    = false,
    priority = 100,
    version = "v2.*",
    build   = "make install_jsregexp",
    dependencies = { "rafamadriz/friendly-snippets" },
    config = function()
      require("luasnip.loaders.from_vscode").lazy_load({
        exclude = { "latex", "tex" },
      })
      require("luasnip.loaders.from_lua").lazy_load({
        paths = { vim.fn.stdpath("config") .. "/snippets" },
      })
    end,
  },

  -- Completion
  { "hrsh7th/nvim-cmp",
    lazy = false,
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "f3fora/cmp-spell",
      "saadparwaiz1/cmp_luasnip",
    },
  },

  -- Colorscheme
  { "folke/tokyonight.nvim", lazy = false, priority = 1000,
    config = function() vim.cmd.colorscheme("tokyonight-night") end,
  },
})

-- ============================================================
-- Completion (nvim-cmp) — SIMPLIFIED for diagnosis
-- ============================================================
local cmp     = require("cmp")
local luasnip = require("luasnip")

cmp.setup({
  completion = {
    keyword_length = 1,
  },
  snippet = {
    expand = function(args) luasnip.lsp_expand(args.body) end,
  },
  mapping = cmp.mapping.preset.insert({
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<CR>"]      = cmp.mapping.confirm({ select = true }),
    ["<Tab>"]     = cmp.mapping.select_next_item(),
    ["<S-Tab>"]   = cmp.mapping.select_prev_item(),
  }),
  sources = {
    { name = "nvim_lsp" },
    { name = "luasnip" },
    { name = "buffer" },
  },
})

-- Treat backslash as part of a word in TeX buffers
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "tex", "plaintex", "context", "bib" },
  callback = function() vim.opt_local.iskeyword:append("\\") end,
})

-- ============================================================
-- Digestif LSP (Neovim 0.11+ native API)
-- ============================================================
local capabilities = require("cmp_nvim_lsp").default_capabilities()

vim.lsp.config("digestif", {
  cmd = { "digestif" },
  filetypes = { "tex", "plaintex", "context", "bib" },
  root_dir = function(bufnr, on_dir)
    local fname = vim.api.nvim_buf_get_name(bufnr)
    local dir = vim.fs.root(bufnr, { ".git", "main.tex", "Makefile" })
              or vim.fs.dirname(fname)
    on_dir(dir)
  end,
  capabilities = capabilities,
})

vim.lsp.enable("digestif")

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local bufnr = args.buf
    local opts = { buffer = bufnr, silent = true }
    vim.keymap.set("n", "K",  vim.lsp.buf.hover,        opts)
    vim.keymap.set("n", "gd", vim.lsp.buf.definition,   opts)
    vim.keymap.set("n", "gr", vim.lsp.buf.references,   opts)
    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename,      opts)
    vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
  end,
})

-- ============================================================
-- Compile & view ConTeXt
-- ============================================================
vim.keymap.set("n", "<leader>cc", function()
  local file = vim.fn.expand("%:p")
  vim.cmd("write")
  vim.cmd("!context " .. vim.fn.shellescape(file))
end, { desc = "Compile with ConTeXt" })

vim.keymap.set("n", "<leader>cv", function()
  local pdf = vim.fn.expand("%:p:r") .. ".pdf"
  vim.fn.jobstart({ "open", pdf }, { detach = true })
end, { desc = "View PDF" })

