{config, ...}: let
  inherit (config.canivete.sops) default;
in {
  perSystem = {lib, pkgs, ...}: {
    config = lib.mkIf config.dotfiles.clouds.hetzner.enable {
      canivete.devShells.shells.default = {
        packages = [pkgs.hcloud];
        shellHook = "export HCLOUD_TOKEN=$(${lib.getExe config.canivete.sops.package} --decrypt --extract '[\"hetzner\"][\"token\"]' \"${default}\")";
      };
    };
  };
  dotfiles = {canivete, config, lib, ...}: {
    options.clouds.hetzner.enable = lib.mkEnableOption "Hetzner Cloud";
    config = lib.mkIf config.clouds.hetzner.enable {
      opentofu.plugins = ["hetznercloud/hcloud"];
      opentofu.modules = {
        provider.hcloud.token = canivete.vals.sops.default "hetzner/token";
        resource.hcloud_ssh_key.me = {
          name = "me";
          public_key = "\${ file(\"\${local.SOPS_DIR}/me.pub\") }";
        };
      };
    };
  };
}
