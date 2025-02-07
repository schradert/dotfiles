{
  # TODO integrate some of the useful bits of this configuration: https://github.com/amix/vimrc
  # TODO use spacevim? https://github.com/SpaceVim/SpaceVim
  # TODO read through https://github.com/mhinz/vim-galore
  # TODO should I use polyglot for languages? https://github.com/sheerun/vim-polyglot
  # NOTE https://github.com/fatih/vim-go
  # NOTE https://github.com/preservim/vim-markdown : NOT the one in polyglot
  # NOTE https://github.com/rust-lang/rust.vim
  # NOTE https://github.com/pangloss/vim-javascript
  # TODO https://github.com/dense-analysis/ale
  # TODO https://github.com/junegunn/fzf.vim
  # TODO https://github.com/mattn/emmet-vim
  # TODO https://github.com/tpope/vim-commentary OR https://github.com/preservim/nerdcommenter
  # TODO https://github.com/tpope/vim-sensible
  # TODO https://github.com/mg979/vim-visual-multi
  # TODO https://github.com/junegunn/vim-easy-align OR https://github.com/godlygeek/tabular
  # TODO https://github.com/tpope/vim-dadbod
  # TODO is this useful at all? https://github.com/justinmk/vim-sneak
  # TODO is this useful at all? https://github.com/ervandew/supertab
  # TODO https://github.com/vim-test/vim-test
  # TODO is this useful at all? https://github.com/mhinz/vim-signify
  # TODO https://github.com/tpope/vim-dispatch
  # TODO https://github.com/wellle/targets.vim
  # TODO https://github.com/tpope/vim-repeat
  # TODO https://github.com/tpope/vim-speeddating
  # TODO https://github.com/svermeulen/vim-cutlass + https://github.com/svermeulen/vim-yoink + https://github.com/svermeulen/vim-subversive
  # TODO what about https://github.com/ludovicchabant/vim-gutentags vs tagbar? + https://github.com/skywind3000/gutentags_plus
  # TODO https://github.com/vim-autoformat/vim-autoformat
  # TODO is there a better version of this https://github.com/waiting-for-dev/vim-www
  # TODO https://github.com/EdenEast/nightfox.nvim
  # TODO https://github.com/skwp/dotfiles
  canivete.deploy.system.homeModules.vim = {
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
