{
  config,
  nix,
  ...
}: let
  inherit (config.canivete.people.my.profiles.default) email;
  inherit (config.dotfiles) domain;
  domainName = nix.replaceStrings ["."] ["-"] domain;
  mkClusterIssuer = name: server: {
    spec.acme = {
      inherit server email;
      privateKeySecretRef = {inherit name;};
      solvers = nix.toList {
        dns01.cloudflare = {
          inherit email;
          apiKeySecretRef.name = "cert-manager";
          apiKeySecretRef.key = "cloudflare_api_key";
        };
        selector.dnsZones = [domain];
      };
    };
  };
in {
  # https://github.com/cert-manager/cert-manager
  perSystem.dotfiles.helm.cert-manager = {
    namespace = "security";
    chart = {
      repo = "https://charts.jetstack.io";
      chart = "cert-manager";
      version = "1.15.3";
      sha256 = "BY20Xn1EZimdwhhT2OL64Hhz42RD9OHlddOzRg0iHNw=";
    };
    values = {
      crds.enabled = true;
      dns01RecursiveNameservers = nix.concatStringsSep "," ["https://1.1.1.1:443/dns-query" "https://1.0.0.1:443/dns-query"];
      dns01RecursiveNameserversOnly = true;
      prometheus.enabled = true;
      prometheus.servicemonitor.enabled = true;
    };
    resources.secrets.cert-manager.stringData.cloudflare_api_key = nix.vals.sops "default.yaml#/cloudflare/api_key";
    resources.clusterissuers = {
      letsencrypt-production = mkClusterIssuer "letsencrypt-production" "https://acme-v02.api.letsencrypt.org/directory";
      letsencrypt-staging = mkClusterIssuer "letsencrypt-staging" "https://acme-staging-v02.api.letsencrypt.org/directory";
    };
    resources.certificates.${domainName}.spec = {
      secretName = "${domainName}-tls";
      issuerRef.name = "letsencrypt-staging";
      issuerRef.kind = "ClusterIssuer";
      commonName = domain;
      dnsNames = [domain "*.${domain}"];
    };
  };
}
