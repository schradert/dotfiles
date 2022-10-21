pkgs: {
  enable = true;
  plugins = with pkgs.vimPlugins; [
    ale
    coc-denite
    coc-json
    # coc-marketplace
    # coc-sh
    # coc-docker
    coc-nvim
    coc-pyright
    coc-vimtex
    csv-vim
    ctrlp-vim
    denite-nvim
    dracula-vim
    jsonc-vim
    nerdtree
    taboo-vim
    tagbar
    terminus
    tmuxline-vim
    undotree
    vimtex
    vim-airline
    vim-airline-themes
    # vim-ctrlspace
    vim-devicons
    vim-flog
    vim-fugitive
    vim-gitgutter
    vim-lastplace
    vim-nix
    vim-startify
    vim-surround
  ];
  settings = {
    ignorecase = true;
    hidden = true;
    history = 1000;
    mouse = "a";
    number = true;
    shiftwidth = 4;
    smartcase = true;
    tabstop = 2;
    expandtab = true;
  };
  extraConfig = ''
    source ~/.vim/preload.vim
    source ~/.vim/nix.vim
  '';
} 
