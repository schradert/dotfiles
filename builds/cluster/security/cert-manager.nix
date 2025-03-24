{
  canivete,
  config,
  lib,
  ...
}: let
  inherit (config.canivete.meta.people.my.profiles.default) email;
  inherit (config.canivete.meta) domain;
  domainName = lib.replaceStrings ["."] ["-"] domain;
  mkClusterIssuer = name: server: {
    spec.acme = {
      inherit server email;
      privateKeySecretRef = {inherit name;};
      solvers = lib.toList {
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
  perSystem.canivete.pre-commit.settings.hooks.lychee.toml.exclude = ["^.+/dns-query$"];
  # https://github.com/cert-manager/cert-manager
  perSystem.canivete.kubenix.helm.cert-manager = {
    namespace = "security";
    chart = {
      repo = "https://charts.jetstack.io";
      chart = "cert-manager";
      version = "1.15.3";
      sha256 = "BY20Xn1EZimdwhhT2OL64Hhz42RD9OHlddOzRg0iHNw=";
    };
    values = {
      crds.enabled = true;
      dns01RecursiveNameservers = lib.concatStringsSep "," ["https://1.1.1.1:443/dns-query" "https://1.0.0.1:443/dns-query"];
      dns01RecursiveNameserversOnly = true;
      prometheus.enabled = true;
      prometheus.servicemonitor.enabled = true;
    };
    resources.secrets.cert-manager.stringData.cloudflare_api_key = canivete.vals.sops "default.yaml#/cloudflare/api_key";
    resources.clusterissuers = {
      letsencrypt-production = mkClusterIssuer "letsencrypt-production" "https://acme-v02.api.letsencrypt.org/directory";
      letsencrypt-staging = mkClusterIssuer "letsencrypt-staging" "https://acme-staging-v02.api.letsencrypt.org/directory";
    };
    resources.certificates.${domainName}.spec = {
      secretName = "${domainName}-tls";
      issuerRef.name = "letsencrypt-production";
      issuerRef.kind = "ClusterIssuer";
      commonName = domain;
      dnsNames = [domain "*.${domain}"];
    };
  };
  canivete.deploy.system.homeModules.cert-manager = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) getExe mkIf;
  in {
    config = mkIf (config.dotfiles.workstation.enable || config.canivete.kubernetes.enable) {
      home.packages = [pkgs.cmctl];
      programs.k9s.plugin.plugins = let
        bash = getExe pkgs.bash;
        cmctl = getExe pkgs.cmctl;
        less = getExe pkgs.less;
      in {
        cert-status = {
          shortCut = "Shift-S";
          description = "Certificate status";
          scopes = ["certificates"];
          confirm = false;
          background = false;
          command = bash;
          args = ["-c" "${cmctl} status certificate --context $CONTEXT --namespace $NAMESPACE $NAME |& ${less}"];
        };
        cert-renew = {
          shortCut = "Shift-R";
          description = "Certificate renew";
          scopes = ["certificates"];
          confirm = true;
          background = false;
          command = bash;
          args = ["-c" "${cmctl} renew --context $CONTEXT --namespace $NAMESPACE $NAME |& ${less}"];
        };
        # TODO get secret from a certificate!
      };
    };
  };
}
