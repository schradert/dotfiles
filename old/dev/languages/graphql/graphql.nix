{
  dotfiles.home-manager = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) mkEnableOption mkIf mkMerge;
    inherit (config.dotfiles.programs) graphql;
  in {
    options.dotfiles.programs.graphql = {
      enable = mkEnableOption "graphql";
      emacs.enable = mkEnableOption "graphql integration in emacs" // {default = config.dotfiles.programs.emacs.enable;};
      vim.enable = mkEnableOption "graphql integration in vim" // {default = config.programs.vim.enable;};
    };
    config = mkIf graphql.enable (mkMerge [
      (mkIf graphql.emacs.enable {
        dotfiles.programs.emacs.orgFiles = [./graphql.org];
        home.packages = [pkgs.nodePackages.graphql-language-service-cli];
      })
      (mkIf graphql.vim.enable {programs.vim.plugins = [pkgs.vimPlugins.vim-graphql];})
    ]);
  };
}
