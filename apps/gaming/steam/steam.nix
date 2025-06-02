{
  dotfiles.nixos = {
    config,
    lib,
    pkgs,
    ...
  }: {
    config = lib.mkIf config.dotfiles.profiles.gaming.enable {
      programs.steam.extraCompatPackages = with pkgs; [proton-ge-bin steamtinkerlaunch steam-play-none];
      programs.steam.protontricks.enable = true;
      programs.gamemode.enable = true;
      programs.gamemode.enableRenice = true;
      home-manager.sharedModules = lib.toList {
        dotfiles.programs.steam.external = {
          enable = true;
          srm.userAccounts = ["supertriggy"];
        };
        home.packages = with pkgs; [heroic steam-tui];
      };
    };
  };
}
