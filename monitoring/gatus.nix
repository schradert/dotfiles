{
  dotfiles = {
    config,
    lib,
    ...
  }: let
    inherit (config) domain;
    inherit (config.services) external-secrets gatus postgres;
    inherit (lib) attrValues mkEnableOption mkIf mkMerge mkOption types;
    inherit (types) attrsOf str submodule;
    tag = "v5.12.0";
    subdomain = "gatus.${domain}";
  in {
    options.services.gatus.enable = mkEnableOption "gatus";
    config = mkMerge [
      {
        # NOTE top-level dotfiles modules don't have pkgs argument...
        kubenix = {pkgs, ...}: {
          options.dotfiles.gatus.endpoints = mkOption {
            default = {};
            description = "Endpoints for Gatus to query on intervals";
            type = attrsOf (submodule ({name, ...}: {
              freeformType = (pkgs.formats.yaml {}).type;
              options.name = mkOption {
                default = name;
                type = str;
                description = "Endpoint title";
              };
              options.url = mkOption {
                type = str;
                description = "Location Gatus needs to query, shows up as subtitle";
              };
              config = {
                # TODO define options
                # NOTE name HAD to be defined to avoid infinite recursion from "inherit name"
                # TODO what other fields/tests should I use?
                group = "external";
                interval = "1m";
                client.dns-resolver = "tcp://1.1.1.1:53";
                conditions = ["[STATUS] == 200"];
              };
            }));
          };
        };
      }
      (mkIf gatus.enable {
        nixos = {pkgs, ...}: {
          canivete.kubernetes.images.gatus = pkgs.dockerTools.pullImage {
            imageName = "twinproduction/gatus";
            imageDigest = "sha256:33f54813d6103796d4493995c8de6915617c84adf929f9a3c6386b987c943e15";
            hash = "sha256-nDTC7ThR746Vm63PouYxZl3PUrMPXRRzrcGiWu8r7EQ=";
            finalImageTag = tag;
          };
        };
        kubenix = {
          config,
          helm,
          ...
        }: {
          dotfiles.gatus.endpoints.gatus.url = "https://${subdomain}";
          dotfiles.postgres.gatus = {};
          kubernetes.helm.releases.gatus = {
            namespace = "monitoring";
            chart = helm.fetch {
              repo = "https://twin.github.io/helm-charts";
              chart = "gatus";
              version = "1.2.0";
              sha256 = "sha256-OiRIfCwPQqfYay66mrg5Qtd7g2bKLUtrIqYDUc6DZk0=";
            };
            extraResources = mkIf (external-secrets.enable && postgres.enable) {
              externalsecrets.gatus.spec = {
                secretStoreRef.name = "kubernetes-default";
                secretStoreRef.kind = "ClusterSecretStore";
                dataFrom = [{extract.key = "gatus.main.credentials.postgresql.acid.zalan.do";}];
                target.template.data.GATUS_DB_URI = "postgres://gatus:{{ .password }}@main.default.svc.cluster.local:5432/gatus";
              };
            };
            values = {
              image = {inherit tag;};
              annotations."secret.reloader.stakater.com/auto" = "true";
              serviceAccount.create = true;
              serviceAccount.autoMount = true;
              ingress = {
                enabled = true;
                ingressClassName = "external";
                annotations."external-dns.alpha.kubernetes.io/target" = "external.${domain}";
                annotations."nginx.ingress.kubernetes.io/auth-url" = "https://oauth2-proxy.${domain}/oauth2/auth";
                annotations."nginx.ingress.kubernetes.io/auth-signin" = "https://oauth2-proxy.${domain}/oauth2/start?rd=$scheme://$host$request_uri";
                hosts = [subdomain];
              };
              secrets = true;
              serviceMonitor.enabled = true;
              config = {
                # TODO decouple from postgres
                storage.type = "postgres";
                storage.path = "$GATUS_DB_URI";
                storage.caching = true;
                metrics = true;
                debug = false;
                ui.title = "Status | Gatus";
                ui.header = "Status";
                connectivity.checker.target = "1.1.1.1:53";
                connectivity.checker.interval = "1m";
                endpoints = attrValues config.dotfiles.gatus.endpoints;
              };
            };
          };
        };
      })
    ];
  };
}
