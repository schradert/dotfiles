{
  inputs,
  moduleWithSystem,
  nix,
  ...
}:
with nix; {
  perSystem = {pkgs, ...}: {
    packages.spicetify-cli = with pkgs;
      spicetify-cli.override {
        buildGoModule = args:
          buildGoModule (args
            // rec {
              version = "2.24.2";
              src = fetchFromGitHub {
                owner = "spicetify";
                repo = args.pname;
                rev = "v${version}";
                sha256 = "jzEtXmlpt6foldLW57ZcpevX8CDc+c8iIynT5nOD9qY=";
              };
              vendorHash = "sha256-rMMTUT7HIgYvxGcqR02VmxOh1ihE6xuIboDsnuOo09g=";
            });
      };
  };
  flake.homeModules.spicetify-nix = inputs.spicetify-nix.homeManagerModule;
  flake.homeModules.spicetify = moduleWithSystem ({
    inputs',
    self',
    ...
  }: {
    config,
    lib,
    ...
  }:
    mkMerge [
      {
        programs.spicetify = with inputs'.spicetify-nix.packages.default; {
          enable = mkDefault true;
          enabledCustomApps = with apps; [
            new-releases
            reddit
            lyrics-plus
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
            genre
            autoSkip
            playNext
            volumePercentage
          ];
          theme = themes.DefaultDynamic;
        };
      }
      (lib.mkIf config.programs.spicetify.enable {
        programs.zsh.initExtraLines = toList "export PATH=\"$HOME/.spicetify:$PATH\"";
        home.shellAliases.spicetify = "spicetify-cli";
        home.packages = [self'.packages.spicetify-cli];
      })
    ]);
}
