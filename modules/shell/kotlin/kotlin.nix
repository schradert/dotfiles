{
  canivete.deploy.system.homeModules.kotlin = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) mkEnableOption mkIf mkMerge mkOption mkPackageOption types;
    inherit (config.dotfiles.programs) kotlin;
  in {
    options.dotfiles.programs.kotlin = {
      enable = mkEnableOption "kotlin";
      emacs.enable = mkEnableOption "kotlin integration in emacs" // {default = config.dotfiles.programs.emacs.enable;};
      vim.enable = mkEnableOption "kotlin integration in vim" // {default = config.programs.vim.enable;};
    };
    config = mkIf kotlin.enable {
      home.packages = [pkgs.kotlin];
      dotfiles.programs.emacs = mkIf kotlin.emacs.enable {
        dependencies = with pkgs; [kotlin-language-server ktlint];
        orgFiles = [./kotlin.org];
      };
      programs.vim.plugins = mkIf kotlin.vim.enable [pkgs.vimPlugins.kotlin-vim];
    };
  };
}
