{
  dotfiles = {
    config,
    lib,
    ...
  }: let
    inherit (config) domain services;
    inherit (lib) mkEnableOption mkForce mkIf mkMerge optional toList;
    image = {
      imageName = "registry.k8s.io/external-dns/external-dns";
      imageDigest = "sha256:f90738b35be265d50141d5c21e6f6049c3da7cd761682c40214117a2951b80bc";
      hash = "sha256-Qmpl5jiDLx+6+vBN7CxcqWh4qvbHyIIKFrlg06rY3mE=";
      finalImageTag = "v0.18.0";
    };
  in {
    options.services.external-dns.enable = mkEnableOption "external-dns";
    config = mkIf services.external-dns.enable {
      nixos = {pkgs, ...}: {
        assertions = toList {
          assertion = services.external-secrets.enable && services.cilium.enable;
          message = "External DNS requires External Secrets and Cilium (Gateway)";
        };
        canivete.kubernetes.images.external-dns = pkgs.dockerTools.pullImage image;
      };
      nixidy = {charts, ...}: let
        chart = charts.external-dns.external-dns;
      in {
        dotfiles.crds.external-dns = {
          src = chart;
          prefix = "crds";
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
                image.repository = image.imageName;
                image.tag = image.finalImageTag;
              }
              (mkIf services.prometheus.enable {serviceMonitor.enabled = true;})
              (mkIf services.reloader.enable {podAnnotations."reloader.stakater.com/auto" = "true";})
            ];
          };
          # Helm chart schema forbids setting this
          resources.deployments.external-dns.spec.template.spec.containers.external-dns.imagePullPolicy = mkForce "Never";
        };
      };
    };
  };
}
