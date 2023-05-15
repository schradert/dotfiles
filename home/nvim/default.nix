pkgs: {
  enable = true;
  coc = {
    enable = true;
    pluginConfig = ''
      
    '';
    settings = { };
  };
  withPython3 = true;
  extraConfig = ''
    luafile $HOME/.config/nixpkgs/settings.lua
  '';
  extraLuaPackages = ps: with ps; [ ];
  extraPackages = [ ];
  extraPython3Packages = ps: with; [ ];
    plugins = with pkgs.vimPlugins;
  [
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
    # (nvim-treesitter.withPlugins (plugins: pkgs.tree-sitter.allGrammars))
    # yankring
    ];
    viAlias = false;
  vimAlias = false;
  vimdiffAlias = true;
}
