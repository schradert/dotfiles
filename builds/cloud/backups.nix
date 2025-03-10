{
  perSystem.canivete.opentofu.workspaces.deploy = {
    plugins = ["backblaze/b2"];
    modules.backblaze = {canivete, ...}: let
      inherit (canivete.vals) sops;
      application_key_id = sops "default.yaml#/backblaze/application_key_id";
      application_key = sops "default.yaml#/backblaze/application_key";
      bucket_name = "t0rdos";
      bucket_type = "allPrivate";
    in {
      provider.b2 = {inherit application_key application_key_id;};
      resource.b2_bucket.main = {inherit bucket_name bucket_type;};
    };
  };
}
