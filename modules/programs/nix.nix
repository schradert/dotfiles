{config, ...}: let
  inherit (config.canivete.people) me;
in {
  canivete.deploy = {
    system.modules.nix = {pkgs, ...}: {
      nix.extraOptions = "experimental-features = nix-command flakes auto-allocate-uids";
      nix.package = pkgs.nixVersions.latest;
    };
    nixos.modules.nix.nix.settings.trusted-users = [me];
    darwin.modules.nix.nix = {
      settings.trusted-users = [me];
      useDaemon = true;
      linux-builder.enable = true;
      linux-builder.systems = ["aarch64-linux"];
    };
    droid.modules.nix.nix.extraOptions = "trusted-users = ${me}";
  };
}
