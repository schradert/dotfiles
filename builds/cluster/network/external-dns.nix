{
  canivete,
  config,
  lib,
  ...
}: let
  secret.name = "external-dns";
  secret.key = "cloudflare_pat";
in {
  # [ ] [external-dns](https://github.com/kubernetes-sigs/external-dns)
  perSystem.canivete.kubenix.helm.external-dns = {
    namespace = "network";
    chart = {
      repo = "https://kubernetes-sigs.github.io/external-dns";
      chart = "external-dns";
      version = "1.14.5";
      sha256 = "2kGZredY6Iw4ucAdG9DOkWbznsOT+AhynSgJdHxlMZQ=";
    };
    resources.secrets.${secret.name}.stringData.${secret.key} = canivete.vals.sops "default.yaml#/cloudflare/pat";
    values = {
      provider.name = "cloudflare";
      env = lib.toList {
        name = "CF_API_TOKEN";
        valueFrom.secretKeyRef = secret;
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
      domainFilters = [config.canivete.meta.domain];
      serviceMonitor.enabled = true;
      podAnnotations."secret.reloader.stakater.com/reload" = secret.name;
      resources.requests.cpu = "13m";
      resources.requests.memory = "42M";
      resources.limits.memory = "42M";
      # TODO spec.template.spec.enableServiceLinks false for deployment?
    };
  };
}
