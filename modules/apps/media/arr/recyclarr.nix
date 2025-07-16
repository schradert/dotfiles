{
  dotfiles = {
    canivete,
    config,
    lib,
    ...
  }: let
    inherit (config) services;
    inherit (lib) mkEnableOption mkIf mkMerge toList;
    image = {
      imageName = "ghcr.io/recyclarr/recyclarr";
      imageDigest = "sha256:759540877f95453eca8a26c1a93593e783a7a824c324fbd57523deffb67f48e1";
      hash = "sha256-2fwbPJY9XItpv6kbvbKte3vriYNfV2rWYMzgkY6akbA=";
      finalImageTag = "7.4.1";
    };
  in {
    options.services.recyclarr.enable = lib.mkEnableOption "recyclarr";
    config = lib.mkIf config.services.recyclarr.enable {
      nixos = {pkgs, ...}: {canivete.kubernetes.images.recyclarr = pkgs.dockerTools.pullImage image;};
      nixidy = {
        charts,
        config,
        pkgs,
        ...
      }: let
        yaml = pkgs.formats.yaml {};
        toYAML = name: yamlObj: builtins.readFile (yaml.generate name yamlObj);
      in {
        options.dotfiles.recyclarr = {
          settings = canivete.mkNullableOption yaml.type {};
          secrets = canivete.mkNullableOption yaml.type {description = "External secret template for recyclar secrets.yml";};
        };
        config = mkMerge [
          (mkIf services.radarr.enable {
            dotfiles.recyclarr.secrets.radarr = "{{ .radarr }}";
            dotfiles.recyclarr.settings.radarr.radarr = {
              base_url = "http" + "://radarr.media.svc.cluster.local";
              api_key = "!secret radarr";
              delete_old_custom_formats = true;
              replace_existing_custom_formats = true;
              include = [
                {template = "radarr-quality-definition-sqp-streaming";}
                {template = "radarr-quality-profile-sqp-1-2160p-default";}
                {template = "radarr-custom-formats-sqp-1-2160p";}
              ];
              quality_profiles = [
                {name = "WEB-1080p";}
                {name = "WEB-2160p";}
              ];
              custom_formats = [
                {
                  trash_ids = ["839bea857ed2c0a8e084f3cbdbd65ecb"]; # x265 (no HDR/DV)
                  assign_scores_to = [{name = "SQP-1 (2160p)";}];
                }
                {
                  trash_ids = [
                    "b6832f586342ef70d9c128d40c07b872" # Bad Dual Groups
                    "cc444569854e9de0b084ab2b8b1532b2" # Black and White Editions
                    "ae9b7c9ebde1f3bd336a8cbd1ec4c5e5" # No-RlsGroup
                    "7357cf5161efbf8c4d5d0c30b4815ee2" # Obfuscated
                    "5c44f52a8714fdd79bb4d98e2673be1f" # Retags
                    "f537cf427b64c38c8e36298f657e4828" # Scene
                  ];
                  assign_scores_to = [{name = "SQP-1 (2160p)";}];
                }
              ];
            };
            applications.recyclarr.resources = mkIf services.external-secrets.enable {
              externalSecrets.recyclarr.spec.data = toList {
                secretKey = "radarr";
                remoteRef.key = "radarr";
              };
            };
          })
          (mkIf services.sonarr.enable {
            dotfiles.recyclarr.secrets.sonarr = "{{ .sonarr }}";
            dotfiles.recyclarr.settings.sonarr.sonarr = {
              base_url = "http" + "://sonarr.media.svc.cluster.local";
              api_key = "!secret sonarr";
              delete_old_custom_formats = true;
              replace_existing_custom_formats = true;
              include = [
                {template = "sonarr-quality-definition-series";}
                {template = "sonarr-v4-quality-profile-web-1080p";}
                {template = "sonarr-v4-custom-formats-web-2160p";}
                {template = "sonarr-v4-quality-profile-web-1080p";}
                {template = "sonarr-v4-custom-formats-web-2160p";}
              ];
              quality_profiles = [
                {name = "WEB-1080p";}
                {name = "WEB-2160p";}
              ];
              custom_formats = [
                {
                  trash_ids = ["9b27ab6498ec0f31a3353992e19434ca"]; # DV (WEBDL)
                  assign_scores_to = [{name = "WEB-2160p";}];
                }
                {
                  trash_ids = [
                    "32b367365729d530ca1c124a0b180c64" # Bad Dual Groups
                    "82d40da2bc6923f41e14394075dd4b03" # No-RlsGroup
                    "e1a997ddb54e3ecbfe06341ad323c458" # Obfuscated
                    "06d66ab109d4d2eddb2794d21526d140" # Retags
                    "1b3994c551cbb92a2c781af061f4ab44" # Scene
                  ];
                  assign_scores_to = [
                    {name = "WEB-1080p";}
                    {name = "WEB-2160p";}
                  ];
                }
              ];
            };
            applications.recyclarr.resources = mkIf services.external-secrets.enable {
              externalSecrets.recyclarr.spec.data = toList {
                secretKey = "sonarr";
                remoteRef.key = "sonarr";
              };
            };
          })
          {
            applications.recyclarr = {
              namespace = "media";
              dotfiles.volsync.pvcs.recyclarr.title = "recyclarr";
              helm.releases.recyclarr = {
                chart = charts.bjw-s-labs.app-template;
                values = mkMerge [
                  {
                    controllers.recyclarr = {
                      type = "cronjob";
                      cronjob.schedule = "@daily";
                      containers.recyclarr = {
                        image.repository = image.imageName;
                        image.tag = image.finalImageTag;
                        args = ["sync"];
                        envFrom = [{secret = "recyclarr";}];
                      };
                    };
                    persistence.config = {
                      type = "persistentVolumeClaim";
                      accessMode = "ReadWriteOnce";
                      size = "1Gi";
                    };
                    persistence.tmpfs = {
                      type = "emptyDir";
                      globalMounts = [
                        {
                          path = "/config/logs";
                          subPath = "logs";
                        }
                        {
                          path = "/config/repositories";
                          subPath = "repositories";
                        }
                        {
                          path = "/tmp";
                          subPath = "tmp";
                        }
                      ];
                    };
                  }
                  (mkIf (config.dotfiles.recyclarr.settings != null) {
                    configMaps.recyclarr.data."recyclarr.yml" = toYAML "recyclarr.yml" config.dotfiles.recyclarr.settings;
                    persistence.config-file = {
                      type = "configMap";
                      name = "recyclarr";
                      globalMounts = toList {
                        path = "/config/recyclarr.yml";
                        subPath = "recyclarr.yml";
                        readOnly = true;
                      };
                    };
                  })
                ];
              };
              resources = mkIf (services.external-secrets.enable && config.dotfiles.recyclarr.secrets != null) {
                externalSecrets.recyclarr.spec = {
                  secretStoreRef.name = "bitwarden";
                  secretStoreRef.kind = "ClusterSecretStore";
                  target.template.data."secrets.yml" = toYAML "secrets.yml" config.dotfiles.recyclarr.secrets;
                };
              };
            };
          }
        ];
      };
    };
  };
}
