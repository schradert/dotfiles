{config, ...}: let
  inherit (config.canivete.meta.people.my.profiles.default) email;
  # FIXME replace Google with Keycloak
  # FIXME replace Hetzner with Backblaze
in {
  dotfiles = {
    config,
    lib,
    ...
  }: let
    inherit (config) domain;
    inherit (lib) mapAttrs mkEnableOption mkForce mkIf toList;
    version = "0.262.5";
    hostname = "nocodb.${domain}";
    url = "https://${hostname}";
  in {
    # TODO query other enabled services to conditionally apply different resources
    options.services.nocodb.enable = mkEnableOption "NocoDB";
    config = mkIf config.services.nocodb.enable {
      opentofu.passwords.nocodb-jwt.length = 21;
      opentofu.passwords.nocodb-admin.length = 21;
      nixos = {pkgs, ...}: {
        canivete.kubernetes.images.nocodb = pkgs.dockerTools.pullImage {
          imageName = "nocodb/nocodb";
          imageDigest = "sha256:83c536cf6c3aea584b0a25bcc88259451b0e2d60bd0e861f5bfaeaa6e10f21ba";
          hash = "sha256-47E+/YgKePCgoMYVJsUVGHHBK8swTEVSPUqVkSR4sTg=";
          finalImageTag = version;
        };
      };
      kubenix = {
        canivete,
        perSystem,
        pkgs,
        ...
      }: let
        inherit (canivete.vals.sops) default;
        # TODO avoid hardcoding workspace
        inherit (perSystem.config.canivete.opentofu.workspaces.deploy.modules.config.provider) minio;
      in {
        dotfiles.gatus.endpoints.nocodb.url = url;
        dotfiles.postgres.nocodb = {};
        kubernetes.api.resources.core.v1 = {
          # openebs.io/local provisioner only supports ReadWrite Once
          PersistentVolumeClaim.nocodb.spec.accessModes = mkForce ["ReadWriteOnce"];
          # override chart's opinionated env defaults
          Secret.nocodb.data = mkForce (mapAttrs (_: canivete.toBase64) {
            NC_AUTH_JWT_SECRET = default "passwords/nocodb-jwt";
            NC_GOOGLE_CLIENT_ID = default "google/iap/client-id";
            NC_GOOGLE_CLIENT_SECRET = default "google/iap/client-secret";
            NC_ADMIN_EMAIL = email;
            NC_ADMIN_PASSWORD = default "passwords/nocodb-admin";
            NC_S3_BUCKET_NAME = default "hetzner/s3/bucket";
            NC_S3_ACCESS_KEY = default "hetzner/s3/access";
            NC_S3_ACCESS_SECRET = default "hetzner/s3/secret";
            # TODO set up SMTP email plugin
            # NOTE will need to create services username with app password?
            # NC_SMTP_USERNAME = "";
            # NC_SMTP_PASSWORD = "";
          });
        };
        kubernetes.helm.releases.nocodb = {
          dotfiles.volsync.pvcs.nocodb = "nocodb";
          extraResources = {
            externalsecrets.nocodb-db.spec = {
              secretStoreRef.name = "kubernetes-default";
              secretStoreRef.kind = "ClusterSecretStore";
              dataFrom = [{extract.key = "nocodb.main.credentials.postgresql.acid.zalan.do";}];
              # NOTE https://github.com/nocodb/nocodb/issues/8554
              target.template.data."db.json" = builtins.toJSON {
                client = "pg";
                connection = {
                  host = "main";
                  port = 5432;
                  user = "nocodb";
                  password = "{{ .password }}";
                  database = "nocodb";
                  ssl.rejectUnauthorized = false;
                };
              };
            };
            deployments.nocodb = {
              metadata.annotations."kapp.k14s.io/change-group.nocodb-deployment" = "nocodb-deployment";
              metadata.annotations."reloader.stakater.com/auto" = "true";
              spec.template.spec = {
                containers = toList {
                  name = "nocodb";
                  volumeMounts = toList {
                    name = "db";
                    mountPath = "/usr/app/conf/";
                  };
                };
                volumes = toList {
                  name = "db";
                  secret.secretName = "nocodb-db";
                };
              };
            };
            pods.nocodb-test-connection = {
              # Fails if we don't tell it to delay deployment
              # TODO still failed so how can we force it wait some number of seconds?
              metadata.annotations."kapp.k14s.io/change-rule.nocodb-deployment" = "upsert after upserting nocodb-deployment";
              spec.containers = toList {
                name = "wget";
                # Defaults to Always which is incompatible with Spegel airgap
                imagePullPolicy = "Never";
              };
            };
          };
          # Chart isn't hosted anywhere yet
          # NOTE https://github.com/nocodb/nocodb/issues/1544
          chart = pkgs.stdenv.mkDerivation rec {
            name = "nocodb-${version}";
            inherit version;
            src = pkgs.fetchFromGitHub {
              owner = "nocodb";
              repo = "nocodb";
              rev = version;
              hash = "sha256-QESTQ/cHQqmnHKjeRVJdup5jVJg7C0UfeBSKtqE+xo8=";
            };
            nativeBuildInputs = [pkgs.yq];
            # Don't need chart dependencies
            buildPhase = "yq --yaml-roundtrip --in-place '.dependencies |= []' charts/nocodb/Chart.yaml";
            installPhase = "cp -R charts/nocodb $out";
          };
          values = {
            extraEnvs = {
              NC_PUBLIC_URL = url;
              NC_DB_JSON_FILE = "/usr/app/conf/db.json";
              NC_DISABLE_EMAIL_AUTH = "true";
              NC_S3_REGION = minio.minio_region;
              NC_S3_ENDPOINT = minio.minio_server;
              # TODO is this helpful?
              # NC_S3_FORCE_PATH_STYLE = "true";
              # TODO set up SMTP email configuration
              # NC_SMTP_FROM = "";
              # NC_SMTP_HOST = "smtp.gmail.com";
              # NC_SMTP_PORT = "587";
              # NC_SMTP_SECURE = "true";
              # NC_SMTP_IGNORE_TLS = "false";
            };
            image.tag = version;
            serviceAccount.create = true;
            ingress = {
              enabled = true;
              className = "nginx";
              # Invalid Ingress definition without port...
              # Kubenix only supports integers here, not service port names
              port = 8080;
              annotations."external-dns.alpha.kubernetes.io/target" = "nginx.${domain}";
              annotations."nginx.ingress.kubernetes.io/auth-url" = "https://oauth2-proxy.${domain}/oauth2/auth";
              annotations."nginx.ingress.kubernetes.io/auth-signin" = "https://oauth2-proxy.${domain}/oauth2/start?rd=$scheme://$host$request_uri";
              hosts = toList {
                host = hostname;
                paths = toList {
                  path = "/";
                  pathType = "Prefix";
                };
              };
            };
          };
        };
      };
    };
  };
}
