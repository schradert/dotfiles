{
  dotfiles.nixos = {config, lib, ...}: {
    options.dotfiles.profiles.server.enable = lib.mkEnableOption "Make it a server";
    config = lib.mkIf config.dotfiles.profiles.server.enable (lib.mkMerge [
      {
        canivete.kubernetes.enable = true;
        dotfiles.cilium.enable = true;
        dotfiles.profiles.virtualization.enable = true;
      }
      (lib.mkIf (!config.canivete.kubernetes.root) {
        canivete.kubernetes.k3s.server = lib.mkForce "https://192.168.50.58:6443";
        services.k3s.serverAddr = "https://192.168.50.58:6443";
      })
    ]);
  };
}
