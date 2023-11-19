{ pkgs, lib, ... }:
{
  programs.vim = {
    enable = true;
    plugins = with pkgs.vimPlugins; [
      csv-vim
      ctrlp-vim
      dracula-vim
      jsonc-vim
      nerdtree
      taboo-vim
      tagbar
      terminus
      tmuxline-vim
      undotree
      vimspector
      vimtex
      vim-airline
      vim-airline-themes
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
    extraConfig = builtins.readFile ./config.vim; 
  };
} 
