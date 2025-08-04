{
  # NOTE read https://www.reddit.com/r/emacs/comments/g8ecpj/comment/foo64ge/
  # NOTE read https://michaelneuper.com/posts/efficient-latex-editing-with-emacs/
  # NOTE read https://ejenner.com/post/latex-emacs/
  dotfiles.home-manager = {
    config,
    lib,
    pkgs,
    ...
  }: {
    options.dotfiles.programs.latex.enable = lib.mkEnableOption "latex";
    config = lib.mkIf config.dotfiles.programs.latex.enable {
      programs = {
        texlive.enable = true;
        texlive.extraPackages = tpkgs: {inherit (tpkgs) scheme-medium;};
        vim.plugins = [pkgs.vimPlugins.vimtex];
        doom-emacs = {
          extraBinPackages = [pkgs.zathura];
          tangle.init.lang.latex = ["+cdlatex" "+fold" "+lsp"];
          tangle.init.tools.biblio = true;
          # TODO reftex bibliography (reftex-default-bibliography citar-bibliography citar-library-paths citar-notes-paths)
          # TODO yasnippet conflicts
          tangle.config = ''
            (setq +latex-viewers '(zathura))
            (map! :map cdlatex-mode-map :i "TAB" #'cdlatex-tab)
          '';
        };
      };
    };
  };
}
