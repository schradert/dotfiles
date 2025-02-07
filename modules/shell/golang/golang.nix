{
  canivete.deploy.system.homeModules.go = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (config.dotfiles.programs) go;
    inherit (lib) mkEnableOption mkIf mkMerge mkOption mkPackageOption types;
    inherit (types) listOf package;
  in {
    options.dotfiles.programs.go = {
      enable = mkEnableOption "go";
      emacs.enable = mkEnableOption "go integration in emacs" // {default = config.dotfiles.programs.emacs.enable;};
      vim.enable = mkEnableOption "go integration in vim" // {default = config.programs.vim.enable;};
    };
    config = mkIf go.enable (mkMerge [
      {
        programs.go.enable = true;
        programs.go.goPath = ".config/go";
      }
      (mkIf go.emacs.enable {
        dotfiles.programs.emacs = {
          dependencies = with pkgs; [
            gocode-gomod
            gore
            gotests
            gomodifytags
            golangci-lint
            gopls
            gotools
            delve
          ];
          orgFiles = [./golang.org];
        };
      })
      (mkIf go.vim.enable {programs.vim.plugins = with pkgs.vimPlugins; [gotests-vim vim-go];})
    ]);
  };
}
