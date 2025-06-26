{
  dotfiles = {config, lib, ...}: let
    inherit (config.services) cilium;
    inherit (lib) mkEnableOption mkIf toList replaceStrings;
    target = subdomain: "${subdomain}.${config.domain}";
    hostname = "*.${config.domain}";
    allowedRoutes.namespaces.from = "All";
    gateway = _target: address: {
      annotations."external-dns.alpha.kubernetes.io/target" = target _target;
      spec = {
        gatewayClassName = "cilium";
        addresses = toList {
          type = "IPAddress";
          value = address;
        };
        infrastructure.annotations."external-dns.alpha.kubernetes.io/hostname" = target _target;
        listeners = [
          {
            name = "http";
            protocol = "HTTP";
            port = 80;
            inherit hostname allowedRoutes;
          }
          {
            name = "https";
            protocol = "HTTPS";
            port = 443;
            inherit hostname allowedRoutes;
            tls.certificateRefs = toList {
              kind = "Secret";
              name = "${replaceStrings ["."] ["-"] config.domain}-tls";
            };
          }
        ];
      };
    };
  in {
    options.services.cilium.gateway.enable = mkEnableOption "Cilium gateways";
    config = mkIf (cilium.enable && cilium.gateway.enable) {
      kubenix = {
        kubernetes.helm.releases.cilium.extraResources.gateways = {
          internal = gateway "internal" "100.64.1.1";
          external = gateway "external" "100.64.1.2";
        };
      };
    };
  };
}
