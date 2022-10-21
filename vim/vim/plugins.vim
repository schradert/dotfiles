" COC
source ~/.vim/coc.vim

" DENITE (window control)
autocmd FileType denite call s:denite_my_settings()
function! s:denite_my_settings() abort
  nnoremap <silent><buffer><expr> <CR> denite#do_map('do_action')
  nnoremap <silent><buffer><expr> d denite#do_map('do_action', 'delete')
  nnoremap <silent><buffer><expr> p denite#do_map('do_action', 'preview')
  nnoremap <silent><buffer><expr> q denite#do_map('quit')
  nnoremap <silent><buffer><expr> i denite#do_map('open_filter_buffer')
  nnoremap <silent><buffer><expr> <Space> denite#do_map('toggle_select').'j'
endfunction

" CTRLSPACE (control center)
set showtabline=0  " obviated by vim-ctrlspace
let g:CtrlSpaceLoadLastWorkspaceOnStart = 1
let g:CtrlSpaceSaveWorkspaceOnSwitch = 1
let g:CtrlSpaceSaveWorkspaceOnExit = 1
hi link CtrlSpaceSearch IncSearch

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

" ALE (linting engine)
let g:ale_linters_explicit = 1
let g:ale_linters = { 'javascript': ['eslint'] }
" Add ALE error statuses to 'vim-airline'
let g:airline#extensions#ale#enabled = 1

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

