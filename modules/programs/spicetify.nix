{
  inputs,
  nix,
  ...
}: {
  canivete.deploy.darwin.homeModules.spotify = {pkgs, ...}: {home.packages = [pkgs.spotify];};
  canivete.deploy.nixos.modules.spicetify = {
    config,
    pkgs,
    ...
  }: {
    imports = [inputs.spicetify-nix.nixosModules.default];
    config = nix.mkIf config.dotfiles.graphical.enable {
      programs.spicetify = with inputs.spicetify-nix.legacyPackages.${pkgs.system}; {
        enable = nix.mkDefault true;
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
              hash = "sha256-Z4u/RK/lb7kkB4f4MTXh7sPXDFV37ZoUxwdHA3BnSDg=";
            };
          }
        ];
        theme = themes.defaultDynamic;
      };
    };
  };
}
