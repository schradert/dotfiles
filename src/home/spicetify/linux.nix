{ flake, lib, pkgs, ... }:
{
  imports = [ flake.inputs.spicetify-nix.homeManagerModule ];
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "spotify" ];
  nixpkgs.overlays = import ./overlays.nix { inherit (flake.inputs) spicetify-nix; };
  programs.spicetify = {
    enable = true;
    enabledCustomApps = with pkgs.spicePkgs.apps; [
      new-releases
      reddit
      lyrics-plus
      marketplace
      localFiles
      nameThatTune
    ];
    enabledExtensions = with pkgs.spicePkgs.extensions; [
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
    theme = pkgs.spicePkgs.themes.DefaultDynamic;
  };
}
