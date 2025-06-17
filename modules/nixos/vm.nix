{
  dotfiles = {config, ...}: let
    inherit (config) me;
  in {
    nixos = {config, lib, ...}: {
      options.dotfiles.profiles.virtualization.enable = lib.mkEnableOption "virtualization";
      config = lib.mkIf config.dotfiles.profiles.virtualization.enable {
        home-manager.sharedModules = [
          ({pkgs, ...}: {
            home.packages = [pkgs.lazydocker];
          })
        ];
        users.users.${me}.extraGroups = ["docker"];
        virtualisation.docker.enable = true;
      };
    };
  };
}
