{
  flake.overlays.bash-snippets = _: prev: {
    # conflict with pkgs.cheat
    bashSnippets = prev.bashSnippets.overrideAttrs (old: {
      installPhase = ''
        ${old.installPhase}
        mv $out/bin/cheat $out/bin/cheat.sh
      '';
    });
  };
  dotfiles.home-manager = {
    config,
    lib,
    pkgs,
    ...
  }: {
    config = lib.mkIf config.dotfiles.profiles.workstation.enable {
      home.packages = with pkgs;
        lib.mkMerge [
          # NOTE iproute2 not available or replaceable on Darwin
          (lib.mkIf stdenv.hostPlatform.isLinux [bashSnippets])
          [
            # TODO add https://github.com/Julien-cpsn/ATAC/tree/main/example_resources
            # TODO compare atac vs slumber
            atac
            binsider
            csv-tui
            csvlens
            desed
            fzf-make
            glow
            hexyl
            httpie
            hyperfine
            imtui
            oha
            otree
            sc-im
            slumber
            tabiew
            tdf
            visidata
            zathura
          ]
        ];
      programs.jq.enable = true;
      programs.jqp.enable = true;
    };
  };
}
