{
  # TODO build https://github.com/Gnarus-G/maccel
  # TODO compile untahris https://www.roguetemple.com/z/untahris/download.php
  # TODO compile NotEye/Hydra Slayer https://github.com/zenorogue/noteye
  # TODO package ADOM https://www.adom.de/home/downloads.html
  # TODO find Blood game from MS-DOS
  # TODO doomrl
  # TODO try to run hack-of-life
  # TODO build https://github.com/sachaos/go-life
  # TODO get copies of fallout and fallout2 to combine with bugfixes from fallout-ce + fallout2-ce
  canivete.deploy.system.homeModules.gaming = {
    config,
    lib,
    pkgs,
    ...
  }: {
    options.dotfiles.graphical.gaming.enable = lib.mkEnableOption "gaming tools";
    config = lib.mkIf config.dotfiles.graphical.gaming.enable {
      assertions = lib.toList {
        assertion = config.dotfiles.graphical.enable;
        message = "Gaming devices must be graphical";
      };
      dotfiles.programs.tetrigo.enable = true;
      home.packages = with pkgs; [
        boohu
        brogue-ce
        brutalmaze
        cataclysm-dda-git
        chess-tui
        # TODO connect to crawl https://crawl.develz.org/wordpress/howto
        # TODO self-host crawl server
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

        shattered-pixel-dungeon
        experienced-pixel-dungeon
        summoning-pixel-dungeon
        rat-king-adventure

        # TODO build https://github.com/ekosachev/astray
        # TODO build https://github.com/deepu105/battleship-rs
        # TODO build https://github.com/jeromeschmied/cgol-tui-rs
        # TODO build https://github.com/agl-alexglopez/maze-tui
        # TODO build https://github.com/Amjad50/plastic
        # TODO build https://github.com/ricott1/rebels-in-the-sky
        # TODO build https://github.com/ricott1/sshattrick
        # TODO build https://github.com/jacopograndi/tage
        # TODO build https://gitlab.com/thustle/thardians-rs
        # TODO build https://github.com/ringtailsoftware/zoridor
        # TODO build https://gitlab.com/dustyweb/terminal-phase
        # TODO build https://github.com/zachlatta/sshtron
        # TODO build https://github.com/wojciech-graj/doom-ascii
        # TODO build https://github.com/TheMozg/awk-raycaster
      ];
    };
  };
  canivete.deploy.nixos.homeModules.gaming = {
    config,
    lib,
    pkgs,
    ...
  }: {
    config = lib.mkIf config.dotfiles.graphical.gaming.enable {
      home.packages = with pkgs; [
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
      ];
    };
  };
}
