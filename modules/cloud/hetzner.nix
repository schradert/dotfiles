{config, ...}: let
  inherit (config.canivete.sops) default;
in {
  dotfiles = {
    canivete,
    config,
    lib,
    pkgs,
    ...
  }: {
    options.clouds.hetzner.enable = lib.mkEnableOption "Hetzner Cloud";
    config = lib.mkIf config.clouds.hetzner.enable {
      devenv.packages = [pkgs.hcloud];
      devenv.enterShell = "export HCLOUD_TOKEN=$(${lib.getExe config.canivete.sops.package} --decrypt --extract '[\"hetzner\"][\"token\"]' \"${default}\")";
      opentofu.plugins = ["hetznercloud/hcloud"];
      opentofu.modules = {
        provider.hcloud.token = canivete.vals.sops.default "hetzner";
        resource.hcloud_ssh_key.me = {
          name = "me";
          public_key = "\${ file(\"\${local.SOPS_DIR}/${config.me}.pub\") }";
        };
      };
    };
  };
}
