{
  dotfiles.home-manager = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) mkEnableOption mkIf mkPackageOption;
    inherit (config.dotfiles.programs) javascript;
  in {
    options.dotfiles.programs.javascript = {
      enable = mkEnableOption "nodejs";
      package = mkPackageOption pkgs "nodejs" {};
      emacs.enable = mkEnableOption "javascript integration in emacs" // {default = config.dotfiles.programs.emacs.enable;};
      vim.enable = mkEnableOption "javascript integration in vim" // {default = config.programs.vim.enable;};
    };
    config = mkIf javascript.enable {
      home.packages = [javascript.package];
      dotfiles.programs.emacs = mkIf javascript.emacs.enable {
        dependencies = [pkgs.nodejs];
        orgFiles = [./javascript.org];
      };
      programs.vim.plugins = mkIf javascript.vim.enable [pkgs.vimPlugins.vim-javascript];
    };
  };
}
