{
  canivete.deploy.system.homeModules.wireless = {config, lib, pkgs, ...}: {
    options.dotfiles.graphical.wireless.enable = lib.mkEnableOption "wireless network management";
    config = lib.mkIf config.dotfiles.graphical.wireless.enable {
      assertions = lib.toList {
        assertion = config.dotfiles.graphical.enable;
        message = "Wireless network management is for graphical nodes";
      };
      home.packages = [pkgs.bandwhich];
      # TODO build https://github.com/dmtrKovalenko/blendr or https://github.com/ztroop/btlescan
    };
  };
  canivete.deploy.nixos.homeModules.wireless = {config, lib, pkgs, ...}: {
    config = lib.mkIf config.dotfiles.graphical.wireless.enable {
      home.packages = with pkgs; [
        airgeddon
        blueman
        bluetui
        impala
        overskride
      ];
    };
  };
}
