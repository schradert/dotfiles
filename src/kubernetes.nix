{
  flake.nixosModules.kubernetes = {
    config,
    lib,
    nix,
    pkgs,
    ...
  }: {
    options.dotfiles.kubernetes.enable = nix.mkEnableOption "kubernetes as a service";
    config = lib.mkIf config.dotfiles.kubernetes.enable {
      environment.systemPackages = [pkgs.k3s];
      services.k3s.enable = true;
      services.k3s.configPath = pkgs.toYAML {
        disable = ["traefik"];
        disable-helm-controller = true;
      };
    };
  };
}
