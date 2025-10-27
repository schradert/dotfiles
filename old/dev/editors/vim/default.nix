{
  dotfiles.devenv.git-hooks.hooks.typos.settings.ignored-words = ["enew"];
  dotfiles.home-manager = {
    config,
    pkgs,
    ...
  }: {
    programs.vim = {
      enable = true;
      plugins = with pkgs.vimPlugins; [
        csv-vim
        ctrlp-vim
        dracula-vim
        jsonc-vim
        # TODO how much more use can I get out of this https://github.com/preservim/nerdtree
        nerdtree
        # TODO this was archived. should I still use it?
        taboo-vim
        # TODO https://github.com/preservim/tagbar
        tagbar
        terminus
        # TODO https://github.com/mbbill/undotree
        undotree
        # TODO https://github.com/puremourning/vimspector
        vimspector
        # TODO https://github.com/lervag/vimtex
        vimtex
        # TODO how much more use can I get out of this https://github.com/vim-airline/vim-airline
        # TODO is this better? https://github.com/itchyny/lightline.vim
        vim-airline
        vim-airline-themes
        # TODO https://github.com/ryanoasis/vim-devicons
        vim-devicons
        vim-flog
        # TODO how much more use can I get out of this https://github.com/tpope/vim-fugitive
        vim-fugitive
        # TODO https://github.com/airblade/vim-gitgutter
        vim-gitgutter
        vim-lastplace
        vim-nix
        # TODO https://github.com/mhinz/vim-startify
        vim-startify
        # TODO https://github.com/tpope/vim-surround
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
    programs.vim.defaultEditor = config.dotfiles.editor == "vim";
    programs.zsh.localVariables.VISUAL = "vim";
  };
}
