{
  canivete.pkgs.allowUnfree = ["raycast"];
  dotfiles.home-manager = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (config.dotfiles.services) raycast;
    inherit (lib) hm mkEnableOption mkIf mkPackageOption platforms;
  in {
    options.dotfiles.services.raycast = {
      enable = mkEnableOption "";
      package = mkPackageOption pkgs "raycast" {};
    };
    config = mkIf raycast.enable {
      assertions = [(hm.assertions.assertPlatform "dotfiles.services.raycast" pkgs platforms.darwin)];
      home.packages = [raycast.package];
      launchd.agents.raycast = {
        enable = true;
        config.KeepAlive.Crashed = true;
        config.Program = "${raycast.package}/Applications/Raycast.app/Contents/MacOS/Raycast";
        config.RunAtLoad = true;
      };
    };
  };
}
