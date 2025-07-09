{
  dotfiles = {
    config,
    lib,
    ...
  }: let
    inherit (config) domain services;
    inherit (services) windmill postgres external-secrets spegel;
    inherit (lib) mkEnableOption mkIf toList mkForce mkMerge nameValuePair;
    tag = "1.481.0";
    subdomain = "windmill.${domain}";
  in {
    options.services.windmill.enable = mkEnableOption "Windmill";
    config = mkIf windmill.enable {
      nixos = {pkgs, ...}: {
        canivete.kubernetes.images = {
          windmill = pkgs.dockerTools.pullImage {
            imageName = "ghcr.io/windmill-labs/windmill";
            imageDigest = "sha256:15a2849de93b31e5bc9adc0f731c613c92df38f5fce79a16c0c034c4a3e62037";
            hash = "sha256-UckiIN7vpC2Frxj/+51AgLMIuxOYgKpTWSjwfJqAOQ0=";
            finalImageTag = tag;
          };
          windmill-lsp = pkgs.dockerTools.pullImage {
            imageName = "ghcr.io/windmill-labs/windmill-lsp";
            imageDigest = "sha256:c0dd098ddb8b9d56dfb10219b845054d16803f365d3ff59d120e43e762b44357";
            hash = "sha256-fnzrlbrVObdHiy3aJVqZgV7UhKOZdiut80Js0lwp62Y=";
            finalImageTag = tag;
          };
        };
      };
      kubenix = {helm, ...}: {
        dotfiles.gatus.endpoints.windmill.url = "https://${subdomain}";
        dotfiles.postgres.windmill.users = {
          # Elevated privileges
          # TODO should I create a separate postgres instance for Windmill because of this?
          windmill = ["superuser"];
          # Roles must pre-exist
          windmill_user = [];
          windmill_admin = [];
        };
        kubernetes.helm.releases.windmill = {
          chart = helm.fetch {
            repo = "https://windmill-labs.github.io/windmill-helm-charts/";
            chart = "windmill";
            version = "2.0.395";
            sha256 = "sha256-E2HvBmK07DoG8dRgdcpzXMXC8Ekk76iqaRf9q6cfj9Q=";
          };
          extraResources = mkMerge [
            {
              roles.windmill.rules = [
                {
                  apiGroups = [""];
                  resources = ["pods"];
                  verbs = ["get" "list" "watch" "create" "update" "patch" "delete"];
                }
                {
                  apiGroups = [""];
                  resources = ["pods/log"];
                  verbs = ["get" "list" "watch"];
                }
                {
                  apiGroups = [""];
                  resources = ["pods/attach"];
                  verbs = ["get" "list" "watch" "create" "update" "patch" "delete"];
                }
                {
                  apiGroups = [""];
                  resources = ["events"];
                  verbs = ["get" "list" "watch"];
                }
                # Needs access to connection secrets
                {
                  apiGroups = [""];
                  resources = ["secrets"];
                  verbs = ["get"];
                }
              ];
              roleBindings.windmill.subjects = toList {
                kind = "ServiceAccount";
                name = "windmill";
                namespace = "default";
              };
              roleBindings.windmill.roleRef = {
                kind = "Role";
                name = "windmill";
                apiGroup = "rbac.authorization.k8s.io";
              };
            }
            (mkIf (external-secrets.enable && postgres.enable) {
              externalsecrets.windmill-secret.spec = {
                secretStoreRef.name = "kubernetes-default";
                secretStoreRef.kind = "ClusterSecretStore";
                dataFrom = [{extract.key = "windmill.main.credentials.postgresql.acid.zalan.do";}];
                target.template.data.url = "postgres://windmill:{{ .password }}@main.default.svc.cluster.local:5432/windmill";
              };
            })
          ];
          values = {
            postgresql.enabled = false;
            ingress.className = "external";
            windmill = {
              databaseUrlSecretName = "windmill-secret";
              baseDomain = subdomain;
              cookieDomain = subdomain;
              baseProtocol = "https";
              inherit tag;
              appReplicas = 1;
              app.annotations."secret.reloader.stakater.com/auto" = "true";
              lspReplicas = 1;
              lsp = {inherit tag;};
            };
          };
        };

        kubernetes.api.resources = mkIf spegel.enable {
          apps.v1.Deployment = let
            override = name: {
              spec.template.spec.containers = toList {
                inherit name;
                # NOTE imagePullPolicy = Always is not compatible with air-gapped Spegel
                imagePullPolicy = mkForce "Never";
              };
            };
          in {
            windmill-app = override "windmill-app";
            windmill-lsp = override "windmill-lsp";
            windmill-workers-native = mkMerge [
              (override "windmill-worker")
              {spec.replicas = mkForce 0;}
              {
                # TODO does this actually work to support running python scripts?
                spec.template.spec.containers = toList {
                  name = "windmill-worker";
                  env = toList (nameValuePair "WORKER_TAGS" "python3");
                };
              }
            ];
            windmill-workers-default = mkMerge [
              (override "windmill-worker")
              # At least two are required for simultaneous scripts (e.g. one triggering another)
              {spec.replicas = mkForce 2;}
            ];
          };
        };
      };
    };
  };
}
