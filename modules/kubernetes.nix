{nix, ...}:
with nix; {
  perSystem.canivete.opentofu.workspaces.deploy.modules.k3s-token.resource.random_password.k3s-token.length = 21;
  canivete.deploy.nixos.modules.kubernetes = {
    config,
    flake,
    pkgs,
    ...
  }: let
    cfg = config.dotfiles.kubernetes;
    cfg_k3s = config.services.k3s;
    inherit (flake.config.dotfiles) domain;
  in {
    options.dotfiles.kubernetes = {
      enable = mkEnableOption "kubernetes as a service";
      root = mkEnableOption "node as kubernetes main control plane";
    };
    config = mkIf cfg.enable {
      canivete.secrets."random_password.k3s-token" = "result";
      environment.systemPackages = [pkgs.k3s];
      networking.firewall.allowedTCPPorts = [6443];
      networking.firewall.allowedUDPPorts = [8472];
      services.k3s = mkMerge [
        {
          enable = true;
          tokenFile = "/canivete/secrets/random_password.k3s-token";
          role = mkDefault "agent";
          gracefulNodeShutdown.enable = true;
        }
        (mkIfElse cfg.root {
          clusterInit = true;
          role = "server";
        } {
          serverAddr = "https://${domain}:6443";
        })
        (mkIf (cfg_k3s.role == "server") {
          configPath = pkgs.writers.writeYAML "k3s.yaml" {
            disable = ["traefik"];
            disable-helm-controller = true;
            tls-san = [domain];
          };
        })
      ];
    };
  };
}
