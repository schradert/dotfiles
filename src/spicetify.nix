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
  flake.nixosModules.spicetify = moduleWithSystem ({
    inputs',
    self',
    ...
  }: {
    config,
    lib,
    pkgs,
    ...
  }: {
    config = lib.mkIf config.dotfiles.graphical.enable {
      home-manager.sharedModules = toList {
        imports = [inputs.spicetify-nix.homeManagerModule];
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
            autoSkip
            playNext
            volumePercentage
            # genre
            # Shinyhero36 user account doesn't exist anymore for Spicetify-Genre
            # https://github.com/the-argus/spicetify-nix/issues/50
            # Found this project better-spotify-genres instead
            {
              # name = "better-spotify-genres";
              src = pkgs.fetchFromGitHub {
                owner = "Vexcited";
                repo = "better-spotify-genres";
                rev = "build";
                hash = "sha256-Z4u/RK/lb7kkB4f4MTXh7sPXDFV37ZoUxwdHA3BnSDg=";
              };
              filename = "spotifyGenres.js";
            }
          ];
          theme = themes.DefaultDynamic;
        };
        # TODO is this necessary
        # home.sessionPath = ["${config.home.homeDirectory}/.spicetify"];
        home.shellAliases.spicetify = "spicetify-cli";
        home.packages = [self'.packages.spicetify-cli];
      };
    };
  });
}
