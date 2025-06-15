{
  dotfiles.nixos = {config, lib, ...}: {
    options.dotfiles.server.enable = lib.mkEnableOption "Make it a server";
    config = lib.mkIf config.dotfiles.server.enable {
      dotfiles.virtualization.enable = true;
    };
  };
}
