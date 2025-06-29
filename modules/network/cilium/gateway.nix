{
  dotfiles = {
    config,
    lib,
    ...
  }: let
    inherit (config) domain;
    inherit (lib) mkIf hasSuffix pipe replaceStrings toList;
  in {
    config = mkIf config.services.cilium.enable {
      kubenix = {
        canivete,
        pkgs,
        ...
      }: {
        canivete.ifd.crds.gateways = "gateway.networking.k8s.io/v1/Gateway";
        kubernetes.imports =
          pipe {
            owner = "kubernetes-sigs";
            repo = "gateway-api";
            rev = "v1.2.0";
            hash = "sha256-mGT7PHEHBOK2OAhx3zi6NWzlrZd8pDy5a1sQ3QqClyM=";
          } [
            pkgs.fetchFromGitHub
            (source: source + "/config/crd/standard")
            (canivete.filesets.everything (name: _: hasSuffix ".yaml" name))
          ];
        kubernetes.helm.releases.cilium = {
          values.gatewayAPI.enabled = true;
          extraResources.gateways = let
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
                    tls.certificateRefs = mkIf config.services.cert-manager.enable (toList {
                      kind = "Secret";
                      name = "${replaceStrings ["."] ["-"] domain}-tls";
                      namespace = "security";
                    });
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
