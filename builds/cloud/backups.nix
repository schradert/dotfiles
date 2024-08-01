{nix, ...}: {
  perSystem.canivete.opentofu.workspaces.cloud = {
    plugins = ["Backblaze/b2"];
    modules.backblaze = {
      provider.b2 = {
        application_key = nix.vals.sops "default.yaml#/backblaze/application_key";
        application_key_id = nix.vals.sops "default.yaml#/backblaze/application_key_id";
      };
      resource.b2_bucket.main = {
        bucket_name = "t0rdos";
        bucket_type = "allPrivate";
      };
    };
  };
}
