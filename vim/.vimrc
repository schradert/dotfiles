" general
colorscheme default
syntax on
set tabstop=2
set number " sidebar line numbers
set ruler " cursor row & column numbers
set nofoldenable " expand folds by default
set nocompatible " don't accommodate vi too much
set enc=utf-8 " use unicode by default
set fileencoding=utf-8 " use unicode by default for files
set fileencodings=ucs-bom,utf8 " support ucs & unicode
filetype on " load filetype detection
filetype plugin on " load 'runtimepath'/ftplugin.vim'
filetype indent on " load 'runtimepath'/indent.vim

" autocommands
let maplocalleader = ","
autocmd BufWritePre * :normal gg=G
autocmd FileType vim nnoremap <buffer> <localleader>c I" <esc>
autocmd FileType python,bash,sh nnoremap <buffer> <localleader>c I# <esc>

