{
  config,
  lib,
  ...
}: let
  inherit (config.canivete.sops) default;
in {
  perSystem = {
    config,
    pkgs,
    ...
  }: {
    canivete.devShells.shells.default = {
      packages = [pkgs.hcloud];
      shellHook = "export HCLOUD_TOKEN=$(${lib.getExe config.canivete.sops.package} --decrypt --extract '[\"hetzner\"][\"token\"]' \"${default}\")";
    };
  };
  dotfiles = {config, ...}: {
    options.platforms.hetzner.enable = lib.mkEnableOption "Hetzner Cloud";
    config = lib.mkIf config.platforms.hetzner.enable {
      opentofu.plugins = ["hetznercloud/hcloud"];
      opentofu.modules = {canivete, ...}: {
        provider.hcloud.token = canivete.vals.sops.default "hetzner/token";
      };
    };
  };
}
