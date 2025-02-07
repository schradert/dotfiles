{
  canivete.deploy.system.homeModules.agda = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (config.dotfiles.programs) agda;
    inherit (lib) mkEnableOption mkIf mkPackageOption;
  in {
    options.dotfiles.programs.agda = {
      enable = mkEnableOption "agda";
      package = mkPackageOption pkgs "agda" {};
      vim.enable = mkEnableOption "agda integration in vim" // {default = config.programs.vim.enable;};
      vim.package = mkPackageOption pkgs ["vimPlugins" "vim-agda"] {};
      emacs.enable = mkEnableOption "agda integration in emacs" // {default = config.dotfiles.programs.emacs.enable;};
    };
    config = mkIf agda.enable {
      home.packages = [agda.package];
      programs.vim.plugins = mkIf agda.vim.enable [agda.vim.package];
      dotfiles.programs.emacs.orgFiles = mkIf agda.emacs.enable [./agda.org];
      # TODO what about emacsPackages. agda-editor-tactics, eri
    };
  };
}
