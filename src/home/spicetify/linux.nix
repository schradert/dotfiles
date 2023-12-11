{
  flake,
  lib,
  pkgs,
  ...
}: {
  imports = [flake.inputs.spicetify-nix.homeManagerModule];
  programs.spicetify = let
    spicePkgs = flake.inputs.spicetify-nix.packages.${pkgs.system}.default;
  in {
    enable = true;
    enabledCustomApps = with spicePkgs.apps; [
      new-releases
      reddit
      lyrics-plus
      marketplace
      localFiles
      nameThatTune
    ];
    enabledExtensions = with spicePkgs.extensions; [
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
      genre
      autoSkip
      playNext
      volumePercentage
    ];
    theme = spicePkgs.themes.DefaultDynamic;
  };
}
