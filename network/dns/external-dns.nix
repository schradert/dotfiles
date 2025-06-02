{
  dotfiles = {
    config,
    lib,
    ...
  }: {
    options.services.external-dns.enable = lib.mkEnableOption "external-dns";
    config = lib.mkIf config.services.external-dns.enable {
      opentofu = {
        modules.resource = {
          google_service_account.external-dns = {
            depends_on = ["google_dns_managed_zone.main"];
            account_id = "external-dns";
            display_name = "ExternalDNS";
          };
          google_project_iam_member.external-dns = {
            depends_on = ["google_project_service.iam_billing"];
            project = "\${ google_project.main.project_id }";
            role = "roles/dns.admin";
            member = "\${ google_service_account.external-dns.member }";
          };
          google_service_account_key.external-dns = {
            depends_on = ["google_project_iam_member.external-dns"];
            service_account_id = "\${ google_service_account.external-dns.name }";
          };
        };
        sops.google-external-dns = {
          value = "\${ google_service_account_key.external-dns.private_key }";
          path = ["google" "external-dns"];
        };
      };
      nixos = {pkgs, ...}: {
        canivete.kubernetes.images.external-dns = pkgs.dockerTools.pullImage {
          imageName = "registry.k8s.io/external-dns/external-dns";
          imageDigest = "sha256:37d3a7a05c4638b8177382b80a627c223bd84a53c1a91be137245bd3cfdf9986";
          hash = "sha256-7W8vlKjJwZ2lSbRIMBxcTNUIDGkPlWbU7aLWChASsco=";
          finalImageTag = "v0.16.1";
        };
      };
      kubenix = {
        canivete,
        helm,
        ...
      }: {
        kubernetes.helm.releases.external-dns = {
          namespace = "kube-system";
          chart = helm.fetch {
            repo = "https://kubernetes-sigs.github.io/external-dns";
            chart = "external-dns";
            version = "1.16.0";
            sha256 = "sha256-+kSdNHUW6xHykemRUujqNrIXC7GNaoH9evuCu+s3AdQ=";
          };
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
            serviceMonitor.enabled = true;
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
