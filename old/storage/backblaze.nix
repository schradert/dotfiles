{
  perSystem.canivete.pre-commit.settings.hooks.lychee.toml.exclude = ["http://s3.us-west-004.backblazeb2.com/t0rdos/*"];
  dotfiles.opentofu = {
    passwords.b2-restic.length = 21;
    plugins = ["backblaze/b2"];
    modules = {canivete, ...}: let
      inherit (canivete.vals.sops) default;
      application_key_id = default "backblaze/application_key_id";
      application_key = default "backblaze/application_key";
      bucket_name = "t0rdos";
      bucket_type = "allPrivate";
    in {
      provider.b2 = {inherit application_key application_key_id;};
      resource.b2_bucket.main = {inherit bucket_name bucket_type;};
    };
  };
}
