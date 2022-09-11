" general
colorscheme default
syntax on
set tabstop=2
set shiftwidth=4
set expandtab
set number " sidebar line numbers
set ruler " cursor row & column numbers
set nofoldenable " expand folds by default
set nocompatible " don't accommodate vi too much
set enc=utf-8 " use unicode by default
set fileencoding=utf-8 " use unicode by default for files
set fileencodings=ucs-bom,utf8 " support ucs & unicode
filetype on " load filetype detection
filetype plugin on " load 'runtimepath'/ftplugin.vim'
" filetype indent on " load 'runtimepath'/indent.vim

" autocommands
let maplocalleader = ","
autocmd BufWritePre * :normal gg=G
autocmd FileType vim nnoremap <buffer> <localleader>c I" <esc>
autocmd FileType python,bash,sh nnoremap <buffer> <localleader>c I# <esc>
augroup filetypedetect
    autocmd BufNewFile,BufRead *.code-workspace setl filetype=json
augroup END

" conquer of completion (github.com/neoclide/coc.nvim)
let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
    silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs	https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
    autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif
call plug#begin()
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'neoclide/coc-json', {'tag': '1.6.1'}
Plug 'fannheyward/coc-marketplace'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-fugitive'
call plug#end()

