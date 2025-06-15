{
  dotfiles.nixos = {config, lib, ...}: {
    options.dotfiles.client.video.enable = lib.mkEnableOption "Video processing";
    config = lib.mkIf config.dotfiles.client.video.enable {
      home-manager.sharedModules = [{programs.obs-studio.enable = true;}];
      users.users.tristan.extraGroups = ["video"];
    };
  };
}