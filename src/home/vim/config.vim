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

" TABOO (pretty tabs)
set sessionoptions+=tabpages,globals

" GITGUTTER (diff sign column symbols)
set foldtext=gitgutter#fold#foldtext()
let g:gitgutter_set_sign_backgrounds = 1
let g:gitgutter_highlight_linenrs = 1
let g:gitgutter_preview_win_floating = 1

" CTRLP (fuzzyfinder)
let g:ctrlp_custom_ignore = { 'dir': '\v[\/]\.git$', 'file': '\v\.(exe|so|dll)$', 'link': 'some_bad_symbolic_links' }
let g:ctrlp_show_hidden = 1

" FUGITIVE (git) + FLOG
set statusline^=%{FugitiveStatusline()}

" AIRLINE (status bar)
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#formatter = 'unique_tail_improved'
let g:airline#extensions#tmuxline#enabled = 0
let g:tmuxline_theme = 'lightline'
let g:airline_theme = 'wombat'

" DRACULA (theme)
autocmd ColorScheme dracula hi CursorLine cterm=underline term=underline
let g:airline_theme='dracula'
colorscheme dracula

" LASTPLACE (reopening files)
let g:lastplace_open_folds = 0

" NERDTREE (file browser sidebar)
" Start NERDTree. If a file is specified, move the cursor to its window.
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * NERDTree | if argc() > 0 || exists("s:std_in") | wincmd p | endif
" Close the tab if NERDTree is the only window remaining in it.
autocmd BufEnter * if winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | quit | endif
" If another buffer tries to replace NERDTree, put it in the other window, and bring back NERDTree.
autocmd BufEnter * if bufname('#') =~ 'NERD_tree_\d\+' && bufname('%') !~ 'NERD_tree_\d\+' && winnr('$') > 1
  \ | let buf=bufnr() | buffer# | execute "normal! \<C-W>w" | execute 'buffer'.buf | endif
" Open the existing NERDTree on each new tab.
autocmd BufWinEnter * if getcmdwintype() == '' | silent NERDTreeMirror | endif
" Function to open the file or NERDTree or netrw. Returns: 1 if either file explorer was opened; otherwise, 0.
function! s:OpenFileOrExplorer(...)
    if a:0 == 0 || a:1 == ''
        NERDTree
    elseif filereadable(a:1)
        execute 'edit '.a:1
        return 0
    elseif a:1 =~? '^\(scp\|ftp\)://'
        execute 'Vexplore '.a:1
    elseif isdirectory(a:1)
        execute 'NERDTree '.a:1
    endif
    return 1
endfunction
" Auto commands to handle OS commandline arguments
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc()==1 && !exists('s:std_in') | if <SID>OpenFileOrExplorer(argv()[0]) | wincmd p | enew | wincmd p | endif | endif
" Command to call the OpenFileOrExplorer function.
command! -n=? -complete=file -bar Edit :call <SID>OpenFileOrExplorer('<args>')
" Command-mode abbreviation to replace the :edit Vim command.
cnoreabbrev e Edit

" VIMSPECTOR (debugging)
let g:vimspector_install_gadgets = [ 'debugpy' ]
let g:vimspector_enable_mappings = 'VISUAL_STUDIO'
let g:vimspector_sign_priority = { 'vimspectorBP': 3 }
