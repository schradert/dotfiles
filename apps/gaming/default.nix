{
  dotfiles.home-manager = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) mkEnableOption mkIf mkMerge;
  in {
    options.dotfiles.profiles.gaming.enable = mkEnableOption "gaming tools";
    config = mkIf config.dotfiles.profiles.gaming.enable {
      programs.tetrigo.enable = true;
      home.packages = with pkgs;
        mkMerge [
          [
            boohu
            brogue-ce
            brutalmaze
            cataclysm-dda-git
            chess-tui
            crawl
            crawlTiles
            dopewars
            harmonist
            hyperrogue
            minesweep-rs
            moon-buggy
            narsil
            nethack # TODO nethack-qt/-x11 necessary?
            rogue
            the-legend-of-edgar
            tty-solitaire

            # Pixel Dungeon
            shattered-pixel-dungeon
            experienced-pixel-dungeon
            summoning-pixel-dungeon
            rat-king-adventure

            # Typing
            ngrrram
            smassh
            thokr
          ]
          (mkIf stdenv.hostPlatform.isLinux [
            arx-libertatis
            bastet
            flitter
            galaxis
            heroic
            infra-arcana
            ivan
            keeperrl
            # NOTE pynput broken on Darwin
            pokete
            sil
            sil-q
            steam-tui
            xbomb
            zeroad
            haskellPackages.Allure
          ])
        ];
    };
  };
}
