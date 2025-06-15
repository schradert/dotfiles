{
  dotfiles.nixos = {config, lib, ...}: {
    options.dotfiles.virtualization.enable = lib.mkEnableOption "virtualization";
    config = lib.mkIf config.dotfiles.virtualization.enable {
      home-manager.sharedModules = [
        ({pkgs, ...}: {
          home.packages = [pkgs.lazydocker];
        })
      ];
      users.users.tristan.extraGroups = ["docker"];
      virtualisation.docker.enable = true;
    };
  };
}
