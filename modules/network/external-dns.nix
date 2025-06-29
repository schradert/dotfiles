{
  dotfiles = {
    config,
    lib,
    ...
  }: {
    options.services.external-dns.enable = lib.mkEnableOption "external-dns";
    config = lib.mkIf config.services.external-dns.enable {
      nixos = {pkgs, ...}: {
        canivete.kubernetes.images.external-dns = pkgs.dockerTools.pullImage {
          imageName = "registry.k8s.io/external-dns/external-dns";
          imageDigest = "sha256:85eba2727b410c8f8093d641a4b1a29671878db94d525a70a4108d10ba8eef5f";
          hash = "sha256-Y1jNejGDtfPzgU87Hz+MXDruil7yPlbyoYTHA4OEO58=";
          finalImageTag = "v0.17.0";
        };
      };
      kubenix = {
        canivete,
        helm,
        ...
      }: let
        chart = helm.fetch {
          repo = "https://kubernetes-sigs.github.io/external-dns";
          chart = "external-dns";
          version = "1.17.0";
          sha256 = "sha256-BqagTsZsIquJkzEZNhOIRc7JZLdzA+6cI+ACQ1I8/u4=";
        };
      in {
        canivete.ifd.crds.dnsendpoints = "externaldns.k8s.io/v1alpha1/DNSEndpoint";
        kubernetes.imports = canivete.filesets.files (name: _: lib.hasSuffix ".yaml" name) "${chart}/crds";
        kubernetes.helm.releases.external-dns = {
          namespace = "kube-system";
          inherit chart;
          extraResources.secrets.external-dns.data.cloudflare_pat = canivete.toBase64 (canivete.vals.sops.default "cloudflare/pat");
          values = {
            provider.name = "cloudflare";
            env = lib.toList {
              name = "CF_API_TOKEN";
              valueFrom.secretKeyRef = {
                name = "external-dns";
                key = "cloudflare_pat";
              };
            };
            extraArgs = [
              "--cloudflare-dns-records-per-page=1000"
              "--cloudflare-proxied"
              "--crd-source-apiversion=externaldns.k8s.io/v1alpha1"
              "--crd-source-kind=DNSEndpoint"
              "--events"
              "--ignore-ingress-tls-spec"
              "--ingress-class=external"
            ];
            policy = "sync";
            sources = ["crd" "ingress"];
            txtOwnerId = "main";
            txtPrefix = "k8s.";
            logFormat = "json";
            domainFilters = [config.domain];
            # serviceMonitor.enabled = true;
            podAnnotations."reloader.stakater.com/auto" = "true";
            resources.requests.cpu = "13m";
            resources.requests.memory = "42M";
            resources.limits.memory = "42M";
            # TODO spec.template.spec.enableServiceLinks false for deployment?
          };
        };
      };
    };
  };
}
