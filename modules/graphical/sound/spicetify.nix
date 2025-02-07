{
  canivete.deploy.system.homeModules.spicetify = {
    flake,
    pkgs,
    ...
  }: let
    inherit (flake.inputs.spicetify-nix.legacyPackages.${pkgs.system}) apps extensions themes;
  in {
    imports = [flake.inputs.spicetify-nix.homeManagerModules.default];
    config = {
      programs.spicetify = {
        enabledCustomApps = with apps; [
          newReleases
          reddit
          lyricsPlus
          marketplace
          localFiles
          nameThatTune
        ];
        enabledExtensions = with extensions; [
          bookmark
          keyboardShortcut
          loopyLoop
          shuffle
          popupLyrics
          trashbin
          powerBar
          seekSong
          skipOrPlayLikedSongs
          playlistIcons
          listPlaylistsWithSong
          playlistIntersection
          skipStats
          wikify
          featureShuffle
          songStats
          showQueueDuration
          history
          autoSkip
          playNext
          volumePercentage
          {
            name = "spotifyGenres.js";
            src = pkgs.fetchFromGitHub {
              owner = "Vexcited";
              repo = "better-spotify-genres";
              rev = "build";
              hash = "sha256-yPydeK1lctIyDXi+flRiiC13ADpNdYgrC7M7L46PhGM=";
            };
          }
        ];
        theme = themes.defaultDynamic;
      };
    };
  };
}
