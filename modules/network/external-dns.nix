{
  dotfiles = {
    config,
    lib,
    ...
  }: let
    inherit (config) domain services;
    inherit (lib) mkEnableOption mkIf mkMerge optional toList;
  in {
    options.services.external-dns.enable = mkEnableOption "external-dns";
    config = mkIf services.external-dns.enable {
      nixos = {pkgs, ...}: {
        assertions = toList {
          assertion = services.external-secrets.enable && services.cilium.enable;
          message = "External DNS requires External Secrets and Cilium (Gateway)";
        };
        canivete.kubernetes.images.external-dns = pkgs.dockerTools.pullImage {
          imageName = "registry.k8s.io/external-dns/external-dns";
          imageDigest = "sha256:85eba2727b410c8f8093d641a4b1a29671878db94d525a70a4108d10ba8eef5f";
          hash = "sha256-Y1jNejGDtfPzgU87Hz+MXDruil7yPlbyoYTHA4OEO58=";
          finalImageTag = "v0.17.0";
        };
      };
      nixidy = {charts, ...}: let
        chart = charts.external-dns.external-dns;
      in {
        dotfiles.crds.external-dns = {
          src = chart;
          crds = ["crds/dnsendpoints.externaldns.k8s.io"];
        };
        applications.external-dns = {
          namespace = "kube-system";
          resources.externalSecrets.external-dns.spec = {
            secretStoreRef.name = "bitwarden";
            secretStoreRef.kind = "ClusterSecretStore";
            data = toList {
              secretKey = "token";
              remoteRef.key = "cloudflare/account/token";
            };
          };
          helm.releases.external-dns = {
            inherit chart;
            values = mkMerge [
              {
                provider.name = "cloudflare";
                env = toList {
                  name = "CF_API_TOKEN";
                  valueFrom.secretKeyRef = {
                    name = "external-dns";
                    key = "token";
                  };
                };
                extraArgs =
                  [
                    "--cloudflare-dns-records-per-page=1000"
                    "--crd-source-apiversion=externaldns.k8s.io/v1alpha1"
                    "--crd-source-kind=DNSEndpoint"
                    "--gateway-name=external"
                    # NOTE nested helm chart values are not actually mergeable unfortunately (attrsOf anything)
                  ]
                  ++ optional services.cloudflared.enable "--cloudflare-proxied";
                policy = "sync";
                sources = ["crd" "gateway-httproute"];
                txtOwnerId = "main";
                txtPrefix = "k8s.";
                logFormat = "json";
                domainFilters = [domain];
              }
              (mkIf services.prometheus.enable {serviceMonitor.enabled = true;})
              (mkIf services.reloader.enable {podAnnotations."reloader.stakater.com/auto" = "true";})
            ];
          };
        };
      };
    };
  };
}
