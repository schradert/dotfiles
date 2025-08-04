{
  dotfiles.shared = {lib, ...}: {options.dotfiles.profiles.client.workstation.enable = lib.mkEnableOption "workstation";};
  dotfiles.nixos = {
    config,
    lib,
    ...
  }: {
    config = lib.mkIf config.dotfiles.profiles.client.workstation.enable {
      assertions = lib.toList {
        assertion = config.dotfiles.profiles.client.enable;
        message = "Workstation is for clients";
      };
      dotfiles.profiles.client.code.enable = true;
      dotfiles.profiles.virtualization.enable = true;
      dotfiles.nixpkgs.config.allowUnfreePackages = ["clickup"];
      home-manager.sharedModules = [{dotfiles.profiles.client.workstation.enable = true;}];
    };
  };
  dotfiles.home-manager = {
    config,
    lib,
    pkgs,
    ...
  }: {
    home.packages = lib.mkIf config.dotfiles.profiles.client.workstation.enable [pkgs.clickup];
  };
}
