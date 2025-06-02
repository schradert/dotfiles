{
  flake.overlays.starfetch = _: prev: {
    starfetch = prev.starfetch.overrideAttrs (old: rec {
      version = "${old.version}-git.${prev.lib.substring 0 7 src.rev}";
      src = prev.fetchFromGitHub {
        owner = "Haruno19";
        repo = "starfetch";
        rev = "d0aab03f5c6ca791e759201021eb77e89e0aa20f";
        hash = "sha256-HQxtEdfV+nENmhCVyl/RdciQFSbMIMtJCr5eIV1nA4k=";
      };
    });
  };
  dotfiles = {
    shared = {
      config,
      lib,
      ...
    }: {
      options.dotfiles.profiles.workstation.enable = lib.mkEnableOption "primary workstation configuration";
      config = lib.mkIf config.dotfiles.profiles.workstation.enable {
        dotfiles.containers = true;
        dotfiles.graphical.sound.synth.enable = true;
        dotfiles.programs.godot.enable = true;
      };
    };
    nixos = {
      config,
      flake,
      lib,
      ...
    }: {
      dotfiles.graphical.sound.enable = config.dotfiles.profiles.workstation.enable;
      security.sudo.extraRules = lib.toList {
        users = [flake.config.canivete.me.people.me];
        commands = lib.toList {
          command = "ALL";
          options = ["NOPASSWD"];
        };
      };
      users.mutableUsers = true;
    };
    home-manager = {
      config,
      lib,
      pkgs,
      ...
    }: {
      config = lib.mkIf config.dotfiles.profiles.workstation.enable (lib.mkMerge [
        {
          dotfiles.email = true;
          dotfiles.graphical.sound.music.enable = true;
          dotfiles.graphical.wireless.enable = true;
          dotfiles.profiles = {
            ai.enable = true;
            databases = true;
            reading.enable = true;
          };
          dotfiles.programs = {
            adguardian.enable = true;
            agda.enable = true;
            direnv.enable = true;
            elvish.enable = true;
            go.enable = true;
            graphql.enable = true;
            graphviz.enable = true;
            haskell.enable = true;
            idris.enable = true;
            java.enable = true;
            javascript.enable = true;
            julia.enable = true;
            kotlin.enable = true;
            latex.enable = true;
            lua.enable = true;
            pandoc.enable = true;
            python.enable = true;
            rust.enable = true;
            superfile.enable = true;
            wordnet.enable = true;
            xonsh.enable = true;
            yazi.enable = true;
            zig.enable = true;
          };
          home.packages = with pkgs;
            lib.mkMerge [
              # NOTE pynput broken on Darwin
              (lib.mkIf stdenv.hostPlatform.isLinux [open-interpreter])
              [
                # Art
                artem
                ascii-image-converter
                cbonsai
                cli-pride-flags
                dwt1-shell-color-scripts
                krabby
                mapscii
                pokemonsay
                pokemon-colorscripts-mac
                sssnake
                starfetch
                theattyr
                ttysvr
                vhs

                # Weather
                mousam
                tenki
                wego
                wthrr
              ]
            ];
          programs = {
            gauntlet.enable = true;
            jujutsu.enable = true;
            nushell.enable = true;
          };
        }
        (lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
          programs.imv.enable = true;
          dotfiles.programs.obs-studio.enable = true;
        })
      ]);
    };
  };
}
