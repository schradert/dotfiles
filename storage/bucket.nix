{
  dotfiles = {
    canivete,
    config,
    lib,
    ...
  }: let
    inherit (canivete.vals.sops) default;
    inherit (config.dotfiles.storage.bucket) enable provider;
    inherit (lib) mkEnableOption mkIf mkMerge types;
  in {
    options.dotfiles.storage.bucket = {
      enable = mkEnableOption "Common storage bucket for objects";
      provider = canivete.mkNullableOption (types.enum ["google" "hetzner"]) {description = "Cloud provider with static IP";};
    };
    config = mkIf enable (mkMerge [
      (mkIf (provider == "google") {
        opentofu.plugins = ["opentofu/google"];
        opentofu.modules = {flake, ...}: {
          google_project_service.storage = {
            depends_on = ["google_project_service.resourcemanager"];
            service = "storage.googleapis.com";
          };
          google_storage_bucket.main = {
            depends_on = ["google_project_service.storage"];
            name = "\${ google_project.main.project_id }-main";
            # TODO make dynamic to region
            location = "US-WEST1";
            # NOTE satisfies constraints/storage.uniformBucketLevelAccess
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
        opentofu.plugins = ["aminueza/minio" "hashicorp/random"];
        opentofu.sops.minio_bucket = {
          value = "\${ minio_s3_bucket.main.bucket }";
          path = ["hetzner" "s3" "bucket"];
        };
        opentofu.modules = {
          provider.minio = {
            # No storage buckets in USA yet
            minio_server = "fsn1.your-objectstorage.com";
            minio_user = default "hetzner/s3/access";
            minio_password = default "hetzner/s3/secret";
            minio_region = "fsn1";
            minio_ssl = true;
          };
          resource.random_uuid.bucket = {};
          resource.minio_s3_bucket.main = {
            bucket = "\${ random_uuid.bucket.result }";
            acl = "private";
            object_locking = false;
          };
        };
      })
    ]);
  };
}
