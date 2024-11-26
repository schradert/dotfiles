{
  flake.overlays.silly = _: prev: {
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
  canivete.deploy.system.homeModules.silly = {config, lib, pkgs, ...}: {
    options.dotfiles.programs.silly = lib.mkEnableOption "silly CLI programs for fun";
    config = lib.mkIf config.dotfiles.programs.silly {
      home.packages = with pkgs; [
        artem
        ascii-image-converter
        # conflict with pkgs.cheat
        (bashSnippets.overrideAttrs (old: {
          installPhase = ''
            ${old.installPhase}
            mv $out/bin/cheat $out/bin/cheat.sh
          '';
        }))
        bibata-cursors
        dwt1-shell-color-scripts
        fend
        julia
        kalker
        krabby
        numbat
        pokete
        pokemonsay
        starfetch
        ticker
        tickrs
        tuir

        # Audio
        # TODO follow PR https://github.com/NixOS/nixpkgs/issues/356817
        # cava
        yt-dlp
        youtube-tui

        # browsers
        elinks
        ladybird
        luakit
      ];
    };
  };
}
