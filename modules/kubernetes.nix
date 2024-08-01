{nix, ...}:
with nix; {
  canivete.deploy.nixos.modules.kubernetes = {
    config,
    flake,
    pkgs,
    ...
  }: {
    options.dotfiles.kubernetes.enable = mkEnableOption "kubernetes as a service";
    config = mkIf config.dotfiles.kubernetes.enable {
      environment.systemPackages = [pkgs.k3s];
      networking.firewall.allowedTCPPorts = [6443];
      services.k3s.enable = true;
      services.k3s.configPath = pkgs.writers.writeYAML "k3s.yaml" {
        disable = ["traefik"];
        disable-helm-controller = true;
        tls-san = [flake.config.dotfiles.domain];
      };
    };
  };
}
