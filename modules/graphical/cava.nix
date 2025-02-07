{
  canivete.deploy.system.homeModules.cava = {
    canivete,
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (config.dotfiles.programs) cava;
    inherit (lib) mkIf mkEnableOption mkPackageOption mkMerge mkOption;
    ini = pkgs.formats.ini {};
    configFile = ini.generate "cava-config" cava.settings;
  in {
    options.dotfiles.programs.cava = {
      enable = mkEnableOption "Cava audio visualizer";
      package = mkPackageOption pkgs "cava" {};
      settings = mkOption {
        inherit (ini) type;
        default = {};
      };
    };
    config = mkIf cava.enable (mkMerge [
      {home.packages = [cava.package];}
      (mkIf (cava.settings != {}) (canivete.mkIfElse (config.dotfiles.graphical.gtk.enable or false) {
          xdg.configFile."wpg/templates/cava.config.base".source = configFile;
          xdg.configFile."cava/config".source = config.lib.file.mkOutOfStoreSymlink "${config.xdg.configHome}/wpg/templates/cava.config";
        } {
          xdg.configFile."cava/config".source = configFile;
        }))
    ]);
  };
}
