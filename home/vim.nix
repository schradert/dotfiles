{ pkgs }:
{
  enable = true;
# defaultEditor = true;
  plugins = with pkgs.vimPlugins; [
#   ale
#   coc-denite
#   coc-json
#   coc-pyright
#   coc-vimtex
#   csv-vim
#   ctrlp-vim
#   denite-nvim
#   dracula-vim
#   jsonc-vim
#   nerdtree
#   taboo-vim
#   tagbar
#   terminus
#   tmuxline-vim
#   undotree
#   vimspector
#   vimtex
#   vim-airline
#   vim-airline-themes
#   vim-devicons
#   vim-flog
#   vim-fugitive
#   vim-gitgutter
#   vim-lastplace
#   vim-nix
#   vim-startify
#   vim-surround
  ];
  settings = {
    expandtab = true;
    hidden = true;
    history = 1000;
    ignorecase = true;
    mouse = "a";
    number = true;
    shiftwidth = 4;
    smartcase = true;
    tabstop = 2;
  };
# extraConfig = ''
#   source vim/preload.vim
#   source vim/nix.vim
# '';
} 
