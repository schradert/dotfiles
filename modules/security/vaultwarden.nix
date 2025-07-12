{
  dotfiles = {
    canivete,
    config,
    lib,
    ...
  }: let
    inherit (config) services;
    inherit (lib) mkEnableOption mkIf mkMerge optional toList;
    hostname = "vaultwarden.${config.domain}";
    # TODO why is this failing with 'unsupported image-specific operation on artifact with type "application/vnd.dev.sigstore.bundle.v0.3+json"'
    # image = {
    #   imageName = "vaultwarden/server";
    #   imageDigest = "sha256:07f5ddab7e540a840fd51fe70c226448d4964883e61e535251224ccf8865c494";
    #   hash = "";
    #   finalImageTag = "sha256-c2bbef56931184193554ac612b9e4a2579ac65ad4a043adea6ba02f493f9a8b3";
    # };
    image = {
      imageName = "dotfiles/vaultwarden";
      finalImageTag = "1.34.1";
    };
  in {
    # TODO SMTP
    # TODO WebSockets support through proxy gateway
    # TODO YubiKey OTP server and registered client
    # TODO security integration with network filter
    # TODO alternative authentication for /admin instead of token
    options.services.vaultwarden.enable = mkEnableOption "vaultwarden";
    config = mkIf services.vaultwarden.enable {
      # TODO pass email, base_url, identity_url
      home-manager.programs.rbw.enable = true;
      nixos = {pkgs, ...}: {
        canivete.kubernetes.images.vaultwarden = let
          vaultwarden = pkgs.vaultwarden.override {
            dbBackend =
              if services.postgres.enable
              then "postgresql"
              else "sqlite";
          };
          healthcheck = pkgs.runCommand "vaultwarden-healthcheck.sh" {} ''
            install -D --mode 0755 ${vaultwarden.src}/docker/healthcheck.sh $out/bin/healthcheck.sh
          '';
        in
          pkgs.dockerTools.buildImage {
            name = image.imageName;
            tag = image.finalImageTag;
            copyToRoot = pkgs.buildEnv {
              name = "vaultwarden";
              pathsToLink = ["/bin" "/share"];
              paths = [
                pkgs.curl.bin
                pkgs.busybox
                vaultwarden
                vaultwarden.webvault
                healthcheck
              ];
            };
            runAsRoot = ''
              mkdir -p /usr/bin
              ln -s /bin/env /usr/bin/env
              ln -s /bin/vaultwarden /vaultwarden
              ln -s /bin/healthcheck.sh /healthcheck.sh
              ln -s /share/vaultwarden/vault /web-vault
            '';
            config = {
              Entrypoint = ["/vaultwarden"];
              ExposedPorts."80/tcp" = {};
              Healthcheck = {
                Test = ["/healthcheck.sh"];
                Interval = 60000000000;
                Timeout = 10000000000;
              };
              Volumes."/data" = {};
            };
          };
      };
      opentofu = {
        passwords.vaultwarden.length = 48;
        dotfiles.secrets = {
          "vaultwarden/admin".value = "\${ random_password.vaultwarden.result }";
          "vaultwarden/installation".value = canivete.vals.sops.default "vaultwarden";
        };
      };
      nixidy = {charts, ...}: {
        dotfiles.postgres.vaultwarden = {};
        applications.vaultwarden = {
          namespace = "dotfiles";
          dotfiles.volsync.pvcs.vaultwarden.title = "vaultwarden";
          helm.releases.vaultwarden = {
            chart = charts.bjw-s-labs.app-template;
            values = mkMerge [
              {
                controllers.vaultwarden.containers.vaultwarden = {
                  image.repository = image.imageName;
                  image.tag = image.finalImageTag;
                  probes.liveness.enabled = true;
                  probes.readiness.enabled = true;
                  probes.startup.enabled = true;
                };
                service.vaultwarden.ports.http.port = 80;
                persistence.config = {
                  type = "configMap";
                  name = "vaultwarden";
                  globalMounts = toList {
                    path = "/.env";
                    readOnly = true;
                  };
                };
                persistence.secrets = {
                  type = "secret";
                  name = "vaultwarden";
                  globalMounts = toList {
                    path = "/secrets";
                    readOnly = true;
                  };
                };
                persistence.data = {
                  type = "persistentVolumeClaim";
                  accessMode = "ReadWriteOnce";
                  size = "1Gi";
                  globalMounts = [{path = "/data";}];
                };
                configMaps.vaultwarden.data = {
                  # NOTE further customization https://github.com/dani-garcia/vaultwarden/blob/main/.env.template
                  DOMAIN = "https" + "://${hostname}";
                  ADMIN_TOKEN_FILE = "/secrets/admin_token.txt";
                  SIGNUPS_ALLOWED = "false";
                  SIGNUPS_VERIFY = "true";
                  PUSH_ENABLED = "true";
                  PUSH_INSTALLATION_ID = "41b4a972-2412-450c-8f86-b1cc01772f38";
                  PUSH_INSTALLATION_KEY_FILE = "/secrets/installation_key.txt";
                  SHOW_PASSWORD_HINT = "false";
                };
              }
              (mkIf services.reloader.enable {
                controllers.vaultwarden.annotations."reloader.stakater.com/auto" = "true";
              })
              (mkIf services.cilium.enable {
                route.vaultwarden = {
                  hostnames = [hostname];
                  parentRefs = toList {
                    name = "internal";
                    namespace = "kube-system";
                    sectionName = "https";
                  };
                };
              })
              (mkIf services.postgres.enable {
                configMaps.vaultwarden.data = {
                  PGUSER = "vaultwarden";
                  PGPASSWORD_FILE = "/secrets/db_password.txt";
                  PGHOST = "main.default.svc.cluster.local";
                  PGDATABASE = "vaultwarden";
                };
              })
            ];
          };
          resources = mkMerge [
            (mkIf services.external-secrets.enable {
              externalSecrets.vaultwarden.spec = {
                secretStoreRef.name = "bitwarden";
                secretStoreRef.kind = "ClusterSecretStore";
                data =
                  [
                    {
                      secretKey = "admin_token.txt";
                      remoteRef.key = "vaultwarden/admin";
                    }
                    {
                      secretKey = "installation_key.txt";
                      remoteRef.key = "vaultwarden/installation";
                    }
                  ]
                  ++ (optional services.postgres.enable {
                    secretKey = "db_password.txt";
                    remoteRef.key = "vaultwarden.main.credentials.postgresql.acid.zalan.do";
                    remoteRef.property = "password";
                    sourceRef.storeRef.name = "kubernetes-default";
                    sourceRef.storeRef.kind = "ClusterSecretStore";
                  });
              };
            })
          ];
        };
      };
    };
  };
}
