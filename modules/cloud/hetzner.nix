{config, ...}: let
  inherit (config.canivete.sops) default;
  inherit (config.dotfiles.clouds.hetzner) enable;
in {
  perSystem = {
    config,
    lib,
    pkgs,
    ...
  }: {
    config = lib.mkIf enable {
      canivete.devenv.shells.default = {
        packages = [pkgs.hcloud];
        enterShell = "export HCLOUD_TOKEN=$(${lib.getExe config.canivete.sops.package} --decrypt --extract '[\"hetzner\"][\"token\"]' \"${default}\")";
      };
    };
  };
  dotfiles = {
    canivete,
    config,
    lib,
    ...
  }: {
    options.clouds.hetzner.enable = lib.mkEnableOption "Hetzner Cloud";
    config = lib.mkIf config.clouds.hetzner.enable {
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
