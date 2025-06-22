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
    inherit (lib) flatten flip mkEnableOption mapAttrs mkForce mkIf mkMerge optional types;
    inherit (types) enum str;
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
      buckets = mkAttrsOption str {};
    };
    config = mkIf enable (mkMerge [
      {storage.bucket.buckets.main = "main";}
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
        storage.bucket.minio = {
          server = "https://s3.us-west-004.backblazeb2.com";
          user = default "backblaze/application_key_id";
          password = default "backblaze/application_key";
          region = "us-west-004";
        };
        opentofu = mkIf (!minio.enable) {
          plugins = ["backblaze/b2"];
          modules.provider.b2 = {
            application_key = default "backblaze/application_key";
            application_key_id = default "backblaze/application_key_id";
          };
          modules.resource.b2_bucket = flip mapAttrs buckets (_: bucket_name: {
            inherit bucket_name;
            bucket_type = "allPrivate";
          });
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
