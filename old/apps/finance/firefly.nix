{
  dotfiles = {
    canivete,
    config,
    lib,
    ...
  }: let
    inherit (canivete.vals.sops) default;
    inherit (config) domain services;
    inherit (lib) mkEnableOption mkIf mkMerge;
    hostname = "firefly.${domain}";
    image = {
      imageName = "";
      imageDigest = "";
      hash = "";
      finalImageTag = "";
    };
  in {
    options.services.firefly.enable = mkEnableOption "firefly-iii";
    config = mkIf services.firefly.enable {
      nixos = {pkgs, ...}: {canivete.kubernetes.images.firefly = pkgs.dockerTools.pullImage image;};
      opentofu = {
        passwords = {
          firefly.length = 21;
          firefly-appkey.length = 32;
          firefly-appkey.special = false;
        };
        dotfiles.secrets = {
          "firefly/password".value = "\${ random_password.firefly.result }";
          "firefly/appkey".value = "\${ random_password.firefly-appkey.result }";
        };
      };
      nixidy = {lib, ...}: {
        dotfiles.postgres.firefly = {};
        applications.firefly = {
          namespace = "dotfiles";
          helm.releases.firefly = {
            chart = lib.helm.downloadHelmChart {
              chart = "firefly-iii-stack";
              version = "0.7.3";
              repo = "https://firefly-iii.github.io/kubernetes";
              chartHash = "4nPNT2EFm8dbBVdPoRZzPZYvPouWXVF84VzBo0qis3w=";
            };
            values = mkMerge [
              {
                firefly-iii = {
                  image.tag = "version-6.1.19";
                  persistence.existingClaim = "firefly";
                  config.existingSecret = "firefly";
                  config.env = {
                    AUTHENTICATION_GUARD = "remote_user_guard";
                    AUTHENTICATION_GUARD_HEADER = "HTTP_X_AUTH_REQUEST_PREFERRED_USERNAME";
                    AUTHENTICATION_GUARD_EMAIL = "HTTP_X_AUTH_REQUEST_EMAIL";
                  };
                };
                # TODO https://docs.firefly-iii.org/how-to/data-importer/how-to-configure/
                # TODO https://github.com/dvankley/firefly-plaid-connector-2
                # TODO create access token
                # importer.fireflyiii.auth.accessToken = "firefly_pat";
                importer.enabled = true;
                importer.fireflyiii.vanityUrl = "https" + "://${hostname}";
              }
              (mkIf services.postgres.enable {
                firefly-db.enabled = false;
                firefly-iii.config.env.DB_HOST = "main.storage.svc.cluster.local";
              })
            ];
          };
          resources = mkMerge [
            (mkIf services.reloader.enable {
              deployments.firefly-firefly-iii.metadata.annotations."reloader.stakater.com/auto" = "true";
            })
            (mkIf services.cilium.enable {
              httpRoutes.firefly.spec = {
                hostnames = [hostname];
                parentRefs = toList {
                  name = "internal";
                  namespace = "kube-system";
                  sectionName = "https";
                };
                rules = toList {
                  backendRefs = toList {
                    name = "firefly-firefly-iii";
                    port = 80;
                  };
                };
              };
              httpRoutes.firefly-importer.spec = {
                hostnames = ["firefly-importer-tristan.${domain}"];
                parentRefs = toList {
                  name = "internal";
                  namespace = "kube-system";
                  sectionName = "https";
                };
                rules = toList {
                  backendRefs = toList {
                    name = "firefly-firefly-iii-importer";
                    port = 80;
                  };
                };
              };
            })
            (mkIf (external-secrets.enable && postgres.enable) {
              # TODO share both secrets with app
              externalSecrets.firefly-db.spec = {
                secretStoreRef.name = "kubernetes-default";
                secretStoreRef.kind = "ClusterSecretStore";
                dataFrom = [{extract.key = "firefly.main.credentials.postgresql.acid.zalan.do";}];
                target.template.data.DB_PASSWORD = "{{ .password }}";
              };
              externalSecrets.firefly.spec = {
                secretStoreRef.name = "bitwarden";
                secretStoreRef.kind = "ClusterSecretStore";
                data = [
                  {
                    secretKey = "APP_PASSWORD";
                    remoteRef.key = "firefly/password";
                  }
                  {
                    secretKey = "APP_KEY";
                    remoteRef.key = "firefly/appkey";
                  }
                ];
              };
            })
          ];
        };
      };
    };
  };
}
