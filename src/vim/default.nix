{
  flake.homeModules.vim = {
    config,
    lib,
    nix,
    pkgs,
    ...
  }:
    with nix;
      mkMerge [
        {
          programs.vim = {
            enable = true;
            plugins = with pkgs.vimPlugins;
              [
                csv-vim
                ctrlp-vim
                dracula-vim
                jsonc-vim
                nerdtree
                taboo-vim
                tagbar
                terminus
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
              ]
              ++ optionals config.programs.tmux.enable [
                tmuxline-vim
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
            extraConfig = readFile ./config.vim;
          };
          programs.vim.defaultEditor = config.dotfiles.editor == "vim";
        }
        (lib.mkIf config.programs.vim.enable {
          programs.zsh.localVariables.VISUAL = "vim";
        })
      ];
}
