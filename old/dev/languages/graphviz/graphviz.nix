{
  dotfiles.home-manager = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) mkEnableOption mkIf mkMerge mkPackageOption;
    inherit (config.dotfiles.programs) graphviz;
  in {
    options.dotfiles.programs.graphviz = {
      enable = mkEnableOption "graphviz";
      package = mkPackageOption pkgs "graphviz" {};
      emacs.enable = mkEnableOption "graphviz integration in emacs" // {default = config.dotfiles.programs.emacs.enable;};
      vim.enable = mkEnableOption "graphviz integration in vim" // {default = config.programs.vim.enable;};
      vim.package = mkPackageOption pkgs ["vimPlugins" "graphviz-vim"] {};
    };
    config = mkIf graphviz.enable (mkMerge [
      {home.packages = [graphviz.package];}
      (mkIf graphviz.emacs.enable {dotfiles.programs.emacs.orgFiles = [./graphviz.org];})
      (mkIf graphviz.vim.enable {programs.vim.plugins = [graphviz.vim.package];})
    ]);
  };
}
