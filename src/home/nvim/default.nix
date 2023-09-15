{ pkgs }:
{
  enable = true;
  withPython3 = true;
  extraConfig = ''
    luafile $HOME/.config/nixpkgs/settings.lua
  '';
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
  viAlias = false;
  vimAlias = false;
  vimdiffAlias = false;
}
