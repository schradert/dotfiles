{
  dotfiles = {
    canivete,
    config,
    lib,
    ...
  }: let
    inherit (canivete) mkNullableOption mkAttrsOption;
    inherit (canivete.vals.sops) default;
    inherit (config.storage.bucket) enable provider minio buckets;
    inherit (lib) flatten flip mkEnableOption mapAttrs mkForce mkIf mkMerge optional replaceStrings types;
    inherit (types) coercedTo enum str;
    providers = flatten [
      (optional config.clouds.hetzner.enable "hetzner")
      (optional config.clouds.google.enable "google")
      "backblaze"
    ];
  in {
    options.storage.bucket = {
      enable = mkEnableOption "Common storage bucket for objects";
      provider = mkNullableOption (enum providers) {};
      minio = {
        enable = mkEnableOption "MinIO bucket abstraction";
        server = mkNullableOption str {};
        user = mkNullableOption str {};
        password = mkNullableOption str {};
        region = mkNullableOption str {};
      };
      buckets = mkAttrsOption (coercedTo str (name: "${replaceStrings ["."] ["-"] config.domain}--${name}") str) {};
    };
    config = mkIf enable (mkMerge [
      (mkIf (provider == "google") {
        # TODO GCS MinIO implementation
        storage.bucket.minio.enable = mkForce false;
        # TODO fix implementation
        opentofu.modules = {flake, ...}: {
          google_project_service.storage = {
            depends_on = ["google_project_service.resourcemanager"];
            service = "storage.googleapis.com";
          };
          google_storage_bucket.main = {
            depends_on = ["google_project_service.storage"];
            name = "\${ random_uuid.bucket.result }";
            location = "US-WEST1";
            uniform_bucket_level_access = true;
            foce_destroy = true;
          };
          google_storage_bucket_iam_binding.admin = {
            bucket = "\${ google_storage_bucket.main.name }";
            role = "roles/storage.admin";
            members = [
              "\${ google_service_account.compute.member }"
              "user:${flake.config.canivete.meta.people.my.profiles.default.email}"
            ];
          };
        };
      })
      (mkIf (provider == "hetzner") {
        storage.bucket.minio = {
          # No storage buckets in USA yet
          enable = mkForce true;
          server = "fsn1.your-objectstorage.com";
          user = default "hetzner/s3/access";
          password = default "hetzner/s3/secret";
          region = "fsn1";
        };
      })
      (mkIf (provider == "backblaze") {
        # TODO find necessary capabilities for a new app key for s3 compatibility
        storage.bucket.minio = {
          server = "s3.us-west-004.backblazeb2.com";
          user = default "backblaze/test/key_id";
          password = default "backblaze/test/key";
          region = "us-west-004";
        };
        opentofu = mkIf (!minio.enable) {
          plugins = ["backblaze/b2"];
          sops.backblaze_s3_key_id = {
            value = "\${ b2_application_key.s3.application_key_id }";
            path = ["backblaze" "s3" "key_id"];
          };
          sops.backblaze_s3_key = {
            value = "\${ b2_application_key.s3.application_key }";
            path = ["backblaze" "s3" "key"];
          };
          modules = {
            provider.b2 = {
              application_key = default "backblaze/master/application_key";
              application_key_id = default "backblaze/master/application_key_id";
            };
            resource.b2_application_key.s3 = {
              key_name = "s3";
              capabilities = ["listFiles" "readFiles" "writeFiles" "deleteFiles"];
            };
            resource.b2_bucket = flip mapAttrs buckets (_: bucket_name: {
              inherit bucket_name;
              bucket_type = "allPrivate";
            });
          };
        };
      })
      (mkIf minio.enable {
        opentofu.plugins = ["aminueza/minio"];
        opentofu.modules = {
          provider.minio = {
            minio_server = minio.server;
            minio_user = minio.user;
            minio_password = minio.password;
            minio_region = minio.region;
            minio_ssl = true;
          };
          resource.minio_s3_bucket = flip mapAttrs buckets (_: bucket: {
            inherit bucket;
            acl = "private";
            object_locking = false;
          });
        };
      })
    ]);
  };
}
