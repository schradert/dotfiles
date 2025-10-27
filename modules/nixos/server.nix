{
  dotfiles.nixos = {
    config,
    lib,
    ...
  }: {
    options.dotfiles.profiles.server.enable = lib.mkEnableOption "Make it a server";
    config = lib.mkIf config.dotfiles.profiles.server.enable (lib.mkMerge [
      {
        canivete.kubernetes.enable = true;
        dotfiles.cilium.enable = true;
        dotfiles.profiles.virtualization.enable = true;
      }
    ]);
  };
}
