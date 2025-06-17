{
  dotfiles.nixos = {config, lib, ...}: {
    options.dotfiles.profiles.client.workstation.enable = lib.mkEnableOption "workstation";
    config = lib.mkIf config.dotfiles.profiles.client.workstation.enable {
      assertions = lib.toList {
        assertion = config.dotfiles.profiles.client.enable;
        message = "Workstation is for clients";
      };
      dotfiles.profiles.client.code.enable = true;
      dotfiles.profiles.virtualization.enable = true;
    };
  };
}
