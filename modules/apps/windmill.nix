{
  dotfiles = {
    config,
    lib,
    ...
  }: let
    inherit (config) domain services;
    inherit (services) windmill postgres external-secrets spegel;
    inherit (lib) mkEnableOption mkIf toList mkForce mkMerge nameValuePair;
    tag = "1.507.0";
    hostname = "windmill.${domain}";
    images.windmill = {
      imageName = "ghcr.io/windmill-labs/windmill";
      imageDigest = "sha256:6bb14d0a96a5f32a82fb82589e18244c0956d162772df9b07a662c2a5026f1a6";
      hash = "sha256-6lpAa+D8nwPP4cdRjW6oA42gacxAZYhAX8V5N29d7Ho=";
      finalImageTag = tag;
    };
    images.windmill-lsp = {
      imageName = "ghcr.io/windmill-labs/windmill-lsp";
      imageDigest = "sha256:e5f319fe0b6b694cbef3cace964fff09cc956b72467b108e0bd1785f67d16074";
      hash = "sha256-wCCvsxRx+U+XdzgkzAU6tcu/dlpZeixZH7NO2Wm5FwY=";
      finalImageTag = tag;
    };
  in {
    options.services.windmill.enable = mkEnableOption "Windmill";
    config = mkIf windmill.enable {
      nixos = {pkgs, ...}: {canivete.kubernetes.images = builtins.mapAttrs (_: pkgs.dockerTools.pullImage) images;};
      nixidy = {lib, ...}: {
        dotfiles.gatus.endpoints.windmill.url = "https" + "://${hostname}";
        dotfiles.postgres.windmill.users = {
          # Elevated privileges
          windmill = mkForce "superuser";
          # Roles must pre-exist
          windmill_user = "createdb";
          windmill_admin = "createdb";
        };
        applications.windmill = {
          namespace = "dotfiles";
          helm.releases.windmill = {
            chart = lib.helm.downloadHelmChart {
              chart = "windmill";
              version = "2.0.447";
              repo = "https://windmill-labs.github.io/windmill-helm-charts/";
              chartHash = "sha256-JShs8VdeSJ/nNkwt55LJJSvo4ewyMag3jbJl4h0h62o=";
            };
            values = mkMerge [
              {
                postgresql.enabled = false;
                ingress.enabled = false;
                windmill = {
                  databaseUrlSecretName = "windmill";
                  baseDomain = hostname;
                  cookieDomain = hostname;
                  baseProtocol = "https";
                  inherit tag;
                  appReplicas = 1;
                  lspReplicas = 1;
                  lsp = {inherit tag;};
                };
              }
              (mkIf services.reloader.enable {
                windmill.app.annotations."secret.reloader.stakater.com/auto" = "true";
              })
            ];
          };
          resources = mkMerge [
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
            (mkIf (services.external-secrets.enable && services.postgres.enable) {
              externalSecrets.windmill.spec = {
                secretStoreRef.name = "kubernetes-default";
                secretStoreRef.kind = "ClusterSecretStore";
                dataFrom = [{extract.key = "windmill.main.credentials.postgresql.acid.zalan.do";}];
                target.template.data.url = "postgres://windmill:{{ .password }}@main.default.svc.cluster.local:5432/windmill";
              };
            })
            (mkIf services.spegel.enable {
              deployments = let
                override = name: {
                  spec.template.spec.containers = toList {
                    inherit name;
                    imagePullPolicy = mkForce "Never";
                  };
                };
              in {
                windmill-app = override "windmill-app";
                windmill-lsp = override "windmill-lsp";
                windmill-workers-native = mkMerge [
                  (override "windmill-worker")
                  {
                    spec.replicas = mkForce 0;
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
            })
          ];
        };
      };
    };
  };
}
