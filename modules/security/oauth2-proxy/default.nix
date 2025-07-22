{
  # TODO dragonflydb
  dotfiles = {
    canivete,
    config,
    lib,
    ...
  }: let
    inherit (canivete.vals.sops) default;
    inherit (config) domain services;
    inherit (services.oauth2-proxy) provider;
    inherit (lib) flatten getExe mergeAttrs mkEnableOption mkIf mkMerge optional pipe toList types;
    hostname = "oauth2-proxy.${domain}";
    image = {
      imageName = "quay.io/oauth2-proxy/oauth2-proxy";
      imageDigest = "sha256:2f1471fc735d50dfb0041aeae12967bae42a8387ce1660f0a76b175e3f9c195c";
      hash = "sha256-efDQE58aGHM2s3yE+hyqNijeOCHhaBtr5I1/NwB9hj0=";
      finalImageTag = "v7.10.0";
    };
    providers = flatten [
      (optional config.clouds.google.enable "google")
      (optional services.keycloak.enable "keycloak")
    ];
  in {
    options.services.oauth2-proxy = {
      enable = mkEnableOption "oauth2-proxy";
      provider = canivete.mkNullableOption (types.enum providers) {};
    };
    config = mkIf services.oauth2-proxy.enable {
      nixos = {pkgs, ...}: {canivete.kubernetes.images.oauth2-proxy = pkgs.dockerTools.pullImage image;};
      opentofu = mkMerge [
        {
          plugins = ["scottwinkler/shell"];
          dotfiles.secrets."oauth2-proxy/cookie".value = "\${ shell_script.oauth2-proxy-cookie.output[\"value\"] }";
          modules = {pkgs, ...}: {
            resource.shell_script.oauth2-proxy-cookie.lifecycle_commands = {
              create = ''
                ${getExe pkgs.openssl} rand -base64 32 |
                ${pkgs.coreutils}/bin/head -c 32 |
                ${pkgs.coreutils}/bin/base64 |
                ${getExe pkgs.jq} --raw-input '{"value":.}'
              '';
              delete = "echo";
            };
          };
        }
        (mkIf (provider == "google") {
          dotfiles.secrets = {
            # NOTE These cannot be created programmatically yet because Google has no API for configuring redirection for external apps
            # You can follow their inactivity here https://issuetracker.google.com/issues/116182848?pli=1
            # In the meantime, we do this manually in the interface
            "oauth2-proxy/google/client-id".value = default "oauth2-proxy/google/client-id";
            "oauth2-proxy/google/client-secret".value = default "oauth2-proxy/google/client-secret";
          };
        })
      ];
      nixidy = {
        charts,
        pkgs,
        ...
      }: {
        applications.oauth2-proxy = {
          namespace = "security";
          helm.releases.oauth2-proxy = {
            chart = charts.oauth2-proxy.oauth2-proxy;
            values = {
              config.existingSecret = "oauth2-proxy";
              config.existingConfig = "oauth2-proxy";
              deploymentAnnotations = mkIf services.reloader.enable {"reloader.stakater.com/auto" = "true";};
              metrics.serviceMonitor.enabled = services.prometheus.enable;
              image = {
                repository = image.imageName;
                tag = image.finalImageTag;
                pullPolicy = "Never";
              };
            };
          };
          resources = mkMerge [
            {
              configMaps.oauth2-proxy.data."oauth2_proxy.cfg" =
                pipe
                {
                  google.provider = "google";
                  keycloak.provider = "keycloak-oidc";
                  # TODO dynamic realm name
                  keycloak.oidc_issuer_url = "https" + "://keycloak.${domain}/realms/primary";
                } [
                  (builtins.getAttr provider)
                  (mergeAttrs {
                    redirect_url = "https" + "://${hostname}/oauth2/callback";
                    email_domains = ["*"];
                    code_challenge_method = "S256";
                    skip_provider_button = true;
                    cookie_secure = true;
                    reverse_proxy = true;
                    whitelist_domains = [".${domain}"];
                    cookie_domains = [".${domain}"];
                    set_xauthrequest = true;
                  })
                  (pkgs.writers.writeTOML "oauth2-proxy.cfg")
                  builtins.readFile
                ];
            }
            (mkIf services.cilium.enable {
              httpRoutes.oauth2-proxy.spec = {
                hostnames = [hostname];
                parentRefs = toList {
                  name = "external";
                  namespace = "kube-system";
                  sectionName = "https";
                };
                rules = toList {
                  backendRefs = toList {
                    name = "oauth2-proxy";
                    port = 80;
                  };
                };
              };
            })
            (mkIf services.external-secrets.enable {
              externalSecrets.oauth2-proxy.spec = {
                secretStoreRef.name = "bitwarden";
                secretStoreRef.kind = "ClusterSecretStore";
                data = [
                  {
                    secretKey = "cookie-secret";
                    remoteRef.key = "oauth2-proxy/cookie";
                  }
                  {
                    secretKey = "client-id";
                    remoteRef.key = "oauth2-proxy/${provider}/client-id";
                  }
                  {
                    secretKey = "client-secret";
                    remoteRef.key = "oauth2-proxy/${provider}/client-secret";
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
