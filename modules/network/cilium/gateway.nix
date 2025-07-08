{
  dotfiles = {
    config,
    lib,
    ...
  }: let
    inherit (config) domain services;
    inherit (lib) mkIf replaceStrings toList;
  in {
    config = mkIf services.cilium.enable {
      nixos.assertions = toList {
        assertion = services.external-dns.enable && services.cert-manager.enable;
        message = "Gateway API implementation in Cilium requires External DNS and Cert Manager";
      };
      nixidy = {pkgs, ...}: {
        dotfiles.crds.gateway = {
          install = true;
          prefix = "config/crd/standard";
          application = "cilium";
          src = pkgs.fetchFromGitHub {
            owner = "kubernetes-sigs";
            repo = "gateway-api";
            rev = "v1.2.0";
            hash = "sha256-mGT7PHEHBOK2OAhx3zi6NWzlrZd8pDy5a1sQ3QqClyM=";
          };
        };
        applications.cilium = {
          helm.releases.cilium.values.gatewayAPI.enabled = true;
          resources.gateways = let
            gateway = name: ip: {
              metadata.annotations."external-dns.alpha.kubernetes.io/target" = "${name}.${domain}";
              spec = {
                gatewayClassName = "cilium";
                addresses = toList {
                  type = "IPAddress";
                  value = ip;
                };
                infrastructure.annotations."external-dns.alpha.kubernetes.io/hostname" = "${name}.${domain}";
                listeners = [
                  {
                    name = "http";
                    protocol = "HTTP";
                    port = 80;
                    hostname = "*.${domain}";
                    allowedRoutes.namespaces.from = "All";
                  }
                  {
                    name = "https";
                    protocol = "HTTPS";
                    port = 443;
                    hostname = "*.${domain}";
                    allowedRoutes.namespaces.from = "All";
                    tls.certificateRefs = toList {
                      kind = "Secret";
                      name = "${replaceStrings ["."] ["-"] domain}-tls";
                      namespace = "security";
                    };
                  }
                ];
              };
            };
          in {
            internal = gateway "internal" "192.168.50.251";
            external = gateway "external" "192.168.50.252";
          };
        };
      };
    };
  };
}
