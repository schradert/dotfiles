{
  dotfiles.nixos = {
    config,
    lib,
    pkgs,
    ...
  }: {
    options.dotfiles.profiles.client.gaming.enable = lib.mkEnableOption "Gaming";
    config = lib.mkIf config.dotfiles.profiles.client.gaming.enable {
      assertions = lib.toList {
        assertion = config.dotfiles.profiles.client.enable;
        message = "Gaming is for clients";
      };
      dotfiles.nixpkgs.config.allowUnfreePackages = ["steam" "steam-unwrapped"];
      home-manager.sharedModules = [{home.packages = [pkgs.heroic];}];
      programs.gamemode.enable = true;
      programs.gamemode.enableRenice = true;
      programs.steam.enable = true;
      programs.steam.extraCompatPackages = with pkgs; [proton-ge-bin steamtinkerlaunch steam-play-none];
      programs.steam.protontricks.enable = true;
    };
  };
}
