{inputs, ...}: {
  dotfiles = {
    config,
    lib,
    ...
  }: {
    config = lib.mkIf config.platforms.hetzner.enable {
      opentofu.modules = {flake, ...}: {
        resource.hcloud_ssh_key.me = {
          name = "me";
          public_key = lib.fileContents (inputs.self + "/${flake.config.canivete.sops.directory}/me.pub");
        };
      };
    };
  };
}
