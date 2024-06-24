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
      services.k3s.configPath = pkgs.writers.writeYAML "k3s.yaml" {
        disable = ["traefik"];
        disable-helm-controller = true;
      };
    };
  };
}
