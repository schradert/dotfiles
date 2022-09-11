" general
colorscheme default
syntax on
set tabstop=2
set number " sidebar line numbers
set ruler " cursor row & column numbers
set nofoldenable " expand folds by default
set nocompatible " don't accommodate vi too much
filetype on " load filetype detection
filetype plugin on " load 'runtimepath'/ftplugin.vim'
filetype indent on " load 'runtimepath'/indent.vim

" autocommands
autocmd BufWritePre * :normal gg=G

