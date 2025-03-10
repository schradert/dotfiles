{
  canivete.pkgs.allowUnfree = ["spotify"];
  # TODO choose a music player!!!
  # TODO set up :app emms in doomemacs
  canivete.deploy = {
    nixos.homeModules.music = {
      config,
      lib,
      pkgs,
      ...
    }: {
      config = lib.mkIf config.dotfiles.graphical.sound.music.enable {
        assertions = lib.toList {
          assertion = config.dotfiles.graphical.sound.enable;
          message = "Music only makes sense if sound is enabled";
        };
        home.packages = with pkgs; [scope-tui];
      };
    };
    system.homeModules.music = {
      canivete,
      config,
      lib,
      pkgs,
      ...
    }: let
      inherit (lib) mkDefault mkEnableOption mkIf mkMerge;
    in {
      options.dotfiles.graphical.sound.music.enable = mkEnableOption "music players";
      config = mkIf config.dotfiles.graphical.sound.music.enable {
        dotfiles.programs.cava.enable = true;
        home.packages = with pkgs;
          mkMerge [
            # TODO consider https://github.com/mierak/rmpc
            # TODO consider https://github.com/ravachol/kew
            # TODO consider https://github.com/gmt4/mpvc
            # TODO follow PR https://github.com/NixOS/nixpkgs/issues/356817 (12/1: still stuck in staging)
            # TODO build https://github.com/mps-youtube/yewtube
            [spotube youtube-tui ytui-music]
            (canivete.mkUnless config.programs.spicetify.enable [spotify spotify-player])
          ];
        programs.spicetify.enable = mkDefault true;
      };
    };
  };
}
