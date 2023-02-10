local fn = vim.fn
local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
if fn.empty(fn.glob(install_path)) > 0 then
  packer_bootstrap = fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
end

vim.g.coc_global_extensions = {
  'coc-calc',
  -- 'coc-conjure',       -- clojure
  'coc-css',
  'coc-diagnostic',
  'coc-eslint',
  'coc-elixir',
  'coc-highlight',
  'coc-html',
  'coc-jedi',          -- python
  'coc-jest',
  'coc-json',
  -- 'coc-lua',
  'coc-prettier',
  'coc-pyright',       -- python
  'coc-sh',            -- bash
  'coc-solargraph',    -- ruby
  'coc-spell-checker',
  'coc-tabnine',
  'coc-tsserver',
  'coc-rls',           -- rust
  'coc-vimlsp',
  'coc-yaml',
}

return require('packer').startup(function(use)
  -- snapshot_path = join_paths(stdpath 'cache', 'packer.nvim')

  use 'wbthomason/packer.nvim'
  use {
    'lewis6991/gitsigns.nvim',
    requires = { 'nvim-lua/plenary.nvim' },
    config = function()
      require('gitsigns').setup {
        signs = {
          add          = { hl = 'GitSignsAdd',    text = '+', numhl='GitSignsAddNr',    linehl='GitSignsAddLn'    },
          change       = { hl = 'GitSignsChange', text = '~', numhl='GitSignsChangeNr', linehl='GitSignsChangeLn' },
          delete       = { hl = 'GitSignsDelete', text = '_', numhl='GitSignsDeleteNr', linehl='GitSignsDeleteLn' },
          topdelete    = { hl = 'GitSignsDelete', text = '‾', numhl='GitSignsDeleteNr', linehl='GitSignsDeleteLn' },
          changedelete = { hl = 'GitSignsChange', text = '~', numhl='GitSignsChangeNr', linehl='GitSignsChangeLn' },
        },
        numhl = true
    } end
  }
  use {
    'nvim-telescope/telescope.nvim',
    requires = { {'nvim-lua/plenary.nvim'} }
  }
  use 'clojure-vim/vim-jack-in'
  -- use {'eraserhd/parinfer-rust', run = 'cargo build --release'}
  use 'gpanders/nvim-parinfer'
  use 'github/copilot.vim'
  use 'honza/vim-snippets'
  use 'rktjmp/lush.nvim'
  -- use {
  --   'lukas-reineke/indent-blankline.nvim',
  --   config = require('indent_blankline').setup {
  --     -- char = '¦',
  --     char_highlight_list = {
  --       'IndentLine'
  --     },
  --     enabled = false,
  --     show_first_indent_level = false,
  --   }
  -- }
  use {'neoclide/coc.nvim', branch = 'release'}
  use {
    'nvim-treesitter/nvim-treesitter',
    run = ':TSUpdate',
    config = function()
      require('nvim-treesitter.configs').setup {
        highlight = { enable = true },
        incremental_selection = { enable = true },
        indent = { enable = true }
      }
    end
  }
  use 'nvim-treesitter/playground'
  use 'Olical/conjure'
  use 'preservim/tagbar'
  use 'radenling/vim-dispatch-neovim'
  use 'simnalamburt/vim-mundo'
  -- use 'sheerun/vim-polyglot'
  use 'tpope/vim-commentary'
  use 'tpope/vim-dadbod'
  use 'tpope/vim-dispatch'
  use 'tpope/vim-eunuch'
  use 'tpope/vim-fireplace'
  use 'tpope/vim-fugitive'
  use 'tpope/vim-markdown'
  use 'tpope/vim-repeat'
  use 'tpope/vim-salve'
  use 'tpope/vim-surround'
  use 'vim-nerdtree/nerdtree'
  use 'vim-test/vim-test'
  use 'vimwiki/vimwiki'
  use {
    'windwp/nvim-autopairs',
    config = function()
      require('nvim-autopairs').setup {
        disable_filetype = { 'TelescopePrompt', 'vim' }
      }
    end
  }
  use 'wuelnerdotexe/vim-astro'

  -- Colorschemes
  use 'arcticicestudio/nord-vim'
  use 'gerw/vim-HiLinkTrace'
  use 'jnurmine/Zenburn'
  use 'lifepillar/vim-solarized8'
  use 'morhetz/gruvbox'
  use 'vim-scripts/Wombat'
  use 'yorickpeterse/vim-paper'

  -- Automatically set up your configuration after cloning packer.nvim
  -- Put this at the end after all plugins
  if packer_bootstrap then
    require('packer').sync()
  end
end)

