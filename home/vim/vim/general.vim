syntax enable
set autoread
set cmdheight=2 " doubles size of command line
set updatetime=300 " (default 4000) for smoother updates on write
set ruler " cursor row & column numbers
set nofoldenable " expand folds by default
set nocompatible " don't accommodate vi too much
set encoding=utf-8 " what's the difference?
set enc=utf-8 " use unicode by default
set fileencoding=utf-8 " use unicode by default for files
set fileencodings=ucs-bom,utf8 " support ucs & unicode
set nowrap
set incsearch
set showcmd
set showmatch
set showmode
set hlsearch
set scrolloff=10
set wildignore+=*.docx,*.jpg,*.png,*.gif,*.pdf,*.pyc,*.exe,*.img,*.xlsx,*/tmp/*,*.so,*.swp,*.zip
filetype on " load filetype detection
filetype plugin on " load 'runtimepath'/ftplugin.vim'
let maplocalleader = ","
augroup filetypedetect
  autocmd FileType vim nnoremap <buffer> <localleader>c I" <esc>
  autocmd FileType python,bash,sh nnoremap <buffer> <localleader>c I# <esc>
  autocmd BufNewFile,BufRead *.code-workspace setl filetype=json
augroup END
