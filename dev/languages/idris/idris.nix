{
  # TODO should hoogle run locally or remote?
  dotfiles.home-manager = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) mkEnableOption mkIf mkPackageOption;
    inherit (config.dotfiles.programs) idris;
  in {
    options.dotfiles.programs.idris = {
      enable = mkEnableOption "idris";
      package = mkPackageOption pkgs "idris2" {};
      emacs.enable = mkEnableOption "idris integration in emacs" // {default = config.dotfiles.programs.emacs.enable;};
      vim.enable = mkEnableOption "idris integration in vim" // {default = config.programs.vim.enable;};
    };
    config = mkIf idris.enable {
      dotfiles.programs.emacs = mkIf idris.emacs.enable {
        dependencies = [pkgs.idris2Packages.idris2Lsp];
        orgFiles = [./idris.org];
      };
      home.packages = [idris.package];
      programs.vim.plugins = mkIf idris.vim.enable [pkgs.vimPlugins.idris2-vim];
    };
  };
}
