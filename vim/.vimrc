source ~/.vim/preload.vim
call plug#begin()
Plug 'tpope/vim-surround'
Plug 'wincent/terminus'
Plug 'preservim/tagbar'
Plug 'mbbill/undotree'
Plug 'ryanoasis/vim-devicons'
Plug 'mhinz/vim-startify'
Plug 'neoclide/coc.nvim', {'branch': 'release', 'tag': '*', 'do': { -> coc#util#install()}}
Plug 'neoclide/coc-json', {'tag': '1.6.1'}
Plug 'fannheyward/coc-pyright'
Plug 'fannheyward/coc-marketplace'
Plug 'neoclide/coc-vimtex'
Plug 'neoclide/coc-denite'
Plug 'josa42/coc-sh'
Plug 'josa42/coc-docker'
Plug 'lervag/vimtex'
Plug 'chrisbra/csv.vim'
Plug 'LnL7/vim-nix'
Plug 'neoclide/jsonc.vim'
if has('nvim')
  Plug 'Shougo/denite.nvim', {'do': ':UpdateRemotePlugins'}
else
  Plug 'Shougo/denite.nvim'
  Plug 'roxma/nvim-yarp'
  Plug 'roxma/vim-hug-neovim-rpc'
endif
Plug 'vim-ctrlspace/vim-ctrlspace'
Plug 'gcmt/taboo.vim'
Plug 'airblade/vim-gitgutter'
Plug 'ctrlpvim/ctrlp.vim'
Plug 'tpope/vim-fugitive'
Plug 'rbong/vim-flog'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'edkolev/tmuxline.vim'
Plug 'farmergreg/vim-lastplace'
Plug 'dracula/vim', {'as': 'dracula'}
Plug 'dense-analysis/ale'
Plug 'preservim/nerdtree'
call plug#end()

source ~/.vim/nix-supported-settings.vim
source ~/.vim/nix.vim

