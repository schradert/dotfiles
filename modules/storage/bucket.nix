{
  dotfiles = {
    canivete,
    config,
    lib,
    ...
  }: let
    inherit (canivete) mkNullableOption mkAttrsOption;
    inherit (config.storage) bucket;
    inherit (lib) flatten flip mkEnableOption mapAttrs mkIf mkMerge optional replaceStrings types;
    inherit (types) coercedTo enum str;
    providers = flatten [
      (optional config.clouds.hetzner.enable "hetzner")
      "backblaze"
    ];
  in {
    options.storage.bucket = {
      enable = mkEnableOption "Common storage bucket for objects";
      provider = mkNullableOption (enum providers) {};
      server = mkNullableOption str {};
      user = mkNullableOption str {};
      password = mkNullableOption str {};
      region = mkNullableOption str {};
      buckets = mkAttrsOption (coercedTo str (name: "${replaceStrings ["."] ["-"] config.domain}--${name}") str) {};
    };
    config = mkIf bucket.enable (mkMerge [
      {opentofu.dotfiles.secrets.bucket.value = bucket.password;}
      (mkIf (bucket.provider == "hetzner") {
        storage.bucket.server = "${bucket.region}.your-objectstorage.com";
        opentofu.plugins = ["aminueza/minio"];
        opentofu.modules = {
          provider.minio = {
            minio_server = bucket.server;
            minio_user = bucket.user;
            minio_password = bucket.password;
            minio_region = bucket.region;
            minio_ssl = true;
          };
          resource.minio_s3_bucket = flip mapAttrs bucket.buckets (_: bucket: {
            inherit bucket;
            acl = "private";
            object_locking = false;
          });
        };
      })
      (mkIf (bucket.provider == "backblaze") {
        storage.bucket.server = "s3.${bucket.region}.backblazeb2.com";
        opentofu = {
          plugins = ["backblaze/b2"];
          dotfiles.secrets = {
            "backblaze/s3/id".value = "\${ b2_application_key.s3.application_key_id }";
            "backblaze/s3/key".value = "\${ b2_application_key.s3.application_key }";
          };
          modules = {
            provider.b2 = {
              application_key = bucket.password;
              application_key_id = bucket.user;
            };
            resource.b2_application_key.s3 = {
              key_name = "s3";
              capabilities = ["listFiles" "readFiles" "writeFiles" "deleteFiles"];
            };
            resource.b2_bucket = flip mapAttrs bucket.buckets (_: bucket_name: {
              inherit bucket_name;
              bucket_type = "allPrivate";
            });
          };
        };
      })
    ]);
  };
}
