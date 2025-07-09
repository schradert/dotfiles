{
  dotfiles = {config, ...}: let
    inherit (config) me;
  in {
    nixos = {
      config,
      lib,
      ...
    }: {
      options.dotfiles.profiles.client.video.enable = lib.mkEnableOption "Video processing";
      config = lib.mkIf config.dotfiles.profiles.client.video.enable {
        assertions = lib.toList {
          assertion = config.dotfiles.profiles.client.enable;
          message = "Video is for clients";
        };
        dotfiles.programs.obs-studio.enable = true;
        users.users.${me}.extraGroups = ["video"];
      };
    };
  };
}
