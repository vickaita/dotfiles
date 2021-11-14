local fn = vim.fn
local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
if fn.empty(fn.glob(install_path)) > 0 then
  packer_bootstrap = fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
end

vim.g.coc_global_extensions = {
  'coc-calc',
  'coc-conjure', -- clojure
  'coc-css',
  'coc-diagnostic',
  'coc-eslint',
  'coc-elixir',
  'coc-html',
  'coc-jedi',
  'coc-jest',
  'coc-json',
  'coc-lua',
  'coc-prettier',
  'coc-pyright',
  'coc-solargraph', -- ruby
  'coc-spell-checker',
  'coc-tabnine',
  'coc-tsserver',
  'coc-rls', -- rust
  'coc-yaml',
}

return require('packer').startup(function(use)
  use 'wbthomason/packer.nvim'
  use 'arcticicestudio/nord-vim'
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
        }
    } end
  }
  use {
    'nvim-telescope/telescope.nvim',
    requires = { {'nvim-lua/plenary.nvim'} }
  }
  use 'clojure-vim/vim-jack-in'
  use {'eraserhd/parinfer-rust', run = 'cargo build --release'}
  use 'honza/vim-snippets'
  -- use 'jiangmiao/auto-pairs'
  -- use 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
  -- use 'junegunn/fzf.vim'
  use 'jnurmine/Zenburn'
  use 'lifepillar/vim-solarized8'
  use {
    'lukas-reineke/indent-blankline.nvim',
    config = require('indent_blankline').setup {
      -- char = '¦',
      enabled = false,
      show_first_indent_level = false,
    }
  }
  use {'neoclide/coc.nvim', branch = 'release'}
  use {'Olical/conjure', tag = 'v4.22.1'}
  use 'preservim/tagbar'
  use 'radenling/vim-dispatch-neovim'
  use 'simnalamburt/vim-mundo'
  use 'sheerun/vim-polyglot'
  use 'tpope/vim-commentary'
  use 'tpope/vim-dispatch'
  use 'tpope/vim-eunuch'
  use 'tpope/vim-fireplace'
  use 'tpope/vim-fugitive'
  use 'tpope/vim-markdown'
  use 'tpope/vim-surround'
  use 'vim-airline/vim-airline'
  use 'vim-airline/vim-airline-themes'
  use 'vim-nerdtree/nerdtree'
  use 'vim-test/vim-test'
  use 'vim-scripts/Wombat'
  use 'vimwiki/vimwiki'
  use {
    'windwp/nvim-autopairs',
    config = function()
      require('nvim-autopairs').setup {
        disable_filetype = { 'TelescopePrompt', 'vim' }
      }
    end
  }

  -- Automatically set up your configuration after cloning packer.nvim
  -- Put this at the end after all plugins
  if packer_bootstrap then
    require('packer').sync()
  end
end)

