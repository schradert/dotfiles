{
  # NOTE read https://www.reddit.com/r/emacs/comments/g8ecpj/comment/foo64ge/
  # NOTE read https://michaelneuper.com/posts/efficient-latex-editing-with-emacs/
  # NOTE read https://ejenner.com/post/latex-emacs/
  dotfiles.home-manager = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) mkEnableOption mkIf mkMerge;
    inherit (config.dotfiles.programs) latex;
  in {
    options.dotfiles.programs.latex = {
      enable = mkEnableOption "latex";
      emacs.enable = mkEnableOption "latex integration in emacs" // {default = config.dotfiles.programs.emacs.enable;};
      vim.enable = mkEnableOption "latex integration in vim" // {default = config.programs.vim.enable;};
    };
    config = mkIf latex.enable (mkMerge [
      (mkIf latex.emacs.enable {
        dotfiles.programs.emacs = {
          dependencies = [pkgs.zathura];
          orgFiles = [./latex.org];
        };
        programs.texlive.extraPackages = tpkgs: {inherit (tpkgs) scheme-medium;};
      })
      (mkIf latex.vim.enable {programs.vim.plugins = [pkgs.vimPlugins.vimtex];})
    ]);
  };
}
