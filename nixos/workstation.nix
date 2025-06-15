{
  dotfiles.nixos = {config, lib, ...}: {
    options.dotfiles.client.workstation.enable = lib.mkEnableOption "workstation";
    config = lib.mkIf config.dotfiles.client.workstation.enable {
      dotfiles.client.enable = true;
      dotfiles.client.code.enable = true;
      dotfiles.virtualization.enable = true;
    };
  };
}
