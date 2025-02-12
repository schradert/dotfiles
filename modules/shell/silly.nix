{inputs, ...}: {
  flake.overlays = {
    grim = inputs.grim-hyprland.overlays.default;
    silly = final: prev: {
      starfetch = prev.starfetch.overrideAttrs (old: rec {
        version = "${old.version}-git.${prev.lib.substring 0 7 src.rev}";
        src = prev.fetchFromGitHub {
          owner = "Haruno19";
          repo = "starfetch";
          rev = "d0aab03f5c6ca791e759201021eb77e89e0aa20f";
          hash = "sha256-HQxtEdfV+nENmhCVyl/RdciQFSbMIMtJCr5eIV1nA4k=";
        };
      });
      # conflict with pkgs.cheat
      bashSnippets = prev.bashSnippets.overrideAttrs (old: {
        installPhase = ''
          ${old.installPhase}
          mv $out/bin/cheat $out/bin/cheat.sh
        '';
      });
      # replace youtube-dl everywhere
      yt-dlp = prev.yt-dlp.override {withAlias = true;};
      ytui-music = prev.ytui-music.override {youtube-dl = final.yt-dlp;};
      # broken assertion
      textual-paint = prev.textual-paint.overridePythonAttrs (_: {
        pyproject = true;
        format = null;
      });
      # TODO how do I actually do this build?
      unofficial-angle = final.callPackage ({
        lib,
        stdenv,
        fetchFromGitHub,
        cmake,
        vcpkg,
      }:
        stdenv.mkDerivation rec {
          pname = "angle";
          version = "0.16";
          src = fetchFromGitHub {
            owner = "google";
            repo = "angle";
            rev = "v${version}";
            hash = "";
          };
          postPatch = "cp ${vcpkg.src}/ports/angle/CMakeLists.txt .";
          nativeBuildInputs = [cmake];
          meta = {
            description = "A conformant OpenGL ES implementation for Windows, Mac, Linux, iOS and Android.";
            homepage = "https://github.com/google/angle";
            license = lib.licenses.bsd3;
            maintainers = with lib.maintainers; [schradert];
            platforms = lib.platforms.all;
          };
        }) {};
      ladybird = prev.ladybird.overrideAttrs (old: {
        nativeBuildInputs = old.nativeBuildInputs ++ [final.copyDesktopItems];
        buildInputs = old.buildInputs ++ [final.lcms] ++ final.lib.optional final.stdenv.hostPlatform.isDarwin final.unofficial-angle;
        desktopItems = [
          (final.makeDesktopItem {
            name = "ladybird";
            desktopName = "Ladybird";
            exec = "Ladybird";
            icon = "ladybird";
            comment = old.meta.description;
            categories = ["Network" "InstantMessaging"];
            startupWMClass = "Ladybird";
            terminal = false;
          })
        ];
        postInstall = old.postInstall + "install -D $out/share/Lagom/icons/128x128/app-browser-dark.png $out/share/icons/hicolor/128x128/apps/ladybird.png";
      });
    };
  };
  perSystem = {pkgs, ...}: {
    # TODO figure out what is breaking this! https://discourse.nixos.org/t/buildnpmpackage-enotcached/58832
    packages.webtorrent-cli = pkgs.callPackage ({
      lib,
      buildNpmPackage,
      fetchFromGitHub,
      importNpmLock,
    }:
      buildNpmPackage rec {
        pname = "webtorrent-cli";
        version = "5.1.3";
        src = fetchFromGitHub {
          owner = "webtorrent";
          repo = "webtorrent-cli";
          rev = "refs/tags/v${version}";
          hash = "sha256-hSQ3j5t/k50/D2ZGO1Whh3bgZNIVmPYUrBsd9V1YQZc=";
        };
        npmDeps = importNpmLock {
          npmRoot = src;
          packageLock = lib.importJSON ./package-lock.json;
        };
        inherit (importNpmLock) npmConfigHook;
        meta = {
          description = "WebTorrent, the streaming torrent client. For the command line.";
          homepage = "https://github.com/webtorrent/webtorrent-cli";
          license = lib.licenses.mit;
          maintainers = with lib.maintainers; [schradert];
          platforms = lib.platforms.all;
        };
      }) {};
  };
  canivete.deploy.darwin.modules.silly = {
    config,
    lib,
    ...
  }: {
    config = lib.mkIf config.dotfiles.profiles.silly {
      homebrew.casks = ["sweet-home3d" "freecad"];
    };
  };
  canivete.deploy.nixos.homeModules.silly = {
    canivete,
    config,
    lib,
    pkgs,
    ...
  }: {
    home.packages = lib.mkIf config.dotfiles.profiles.silly (lib.mkMerge [
      (with pkgs; [
        # NOTE iproute2 not available or replaceable on Darwin
        bashSnippets
        # NOTE dependency "libappindicator-gtk3" not available on Darwin
        udiskie
        # NOTE pynput broken on Darwin
        open-interpreter
        sweethome3d.application
        sweethome3d.textures-editor
        sweethome3d.furniture-editor
        kdePackages.kdenlive
        fontfor
        luakit
      ])
      (canivete.mkIfElse config.dotfiles.graphical.hyprland.enable [pkgs.freecad-wayland] [pkgs.freecad])
    ]);
  };
  canivete.deploy.system.modules.silly = {lib, ...}: {
    options.dotfiles.profiles.silly = lib.mkEnableOption "silly CLI programs for fun";
  };
  canivete.deploy.system.homeModules.silly = {
    config,
    lib,
    pkgs,
    ...
  }: {
    config = lib.mkIf config.dotfiles.profiles.silly {
      dotfiles.programs = {
        feh.enable = true;
        wtf.enable = true;
        macchina.enable = true;
        cli-pride-flags.enable = true;
        markmap.enable = true;
        pug.enable = true;
      };
      programs.yt-dlp.enable = true;
      programs.yt-dlp.settings = {};
      home.packages = with pkgs; [
        # Development
        atac
        # TODO add https://github.com/Julien-cpsn/ATAC/tree/main/example_resources
        desed
        lazyjournal
        jqp
        # TODO build https://github.com/felangga/chiko
        # TODO build https://github.com/fipso/cntui
        # TODO build https://github.com/paololazzari/play
        fzf-make
        openapi-tui
        slumber
        trippy
        # TODO build https://github.com/preiter93/wireman
        # TODO build https://github.com/jwt-rs/jwt-ui

        # NOTE see overlay above
        # nodePackages.webtorrent-cli
        webtorrent_desktop
        # TODO build https://github.com/gabrieldemian/vincenzo
        kalker
        krabby
        numbat
        binsider
        hledger
        puffin
        # TODO build https://github.com/dewberryants/asciiMol
        zulip-term
        # TODO build https://github.com/GearKite/MatrixZulipBridge
        toot
        visidata
        # TODO khal + khalorg
        # TODO build https://github.com/mwinters0/hnjobs
        # TODO build https://github.com/nadrad/h-m-m
        upiano
        profanity
        nchat
        # TODO follow gomuks development for when it's rewritten without libolm
        # TODO build https://github.com/mrusme/gomphotherium
        # TODO build https://github.com/quackduck/devzat
        # TODO build https://github.com/mrusme/superhighway84
        # https://github.com/cointop-sh/cointop
        lnav
        pokemonsay
        pokemon-colorscripts-mac
        # TODO build https://github.com/ckaznable/poketex
        starfetch
        ticker
        tickrs
        tuir
        oha
        caligula
        hexyl
        zx
        tut
        so
        python3Packages.howdoi
        hyperfine
        csv-tui
        csvlens
        tabiew
        imtui
        manga-tui
        # TODO build https://github.com/Beastwick18/nyaa
        # TODO build https://github.com/SOF3/lpl
        glow
        systemctl-tui
        tftui
        tuisky
        twitch-tui
        wiki-tui
        nix-output-monitor
        nix-btm
        onefetch
        cpufetch
        fastfetch
        duf
        sherlock
        ytfzf
        cbonsai
        circumflex
        # TODO build https://github.com/pythops/lobtui
        # TODO build https://github.com/Handfish/confetty_rs
        cotp
        # TODO consider https://github.com/eklairs/tlock
        # TODO build https://github.com/ddddddO/packemon
        # TODO build https://github.com/PabloLec/neoss
        mapscii
        trufflehog
        zenith
        httpie
        sc-im
        # TODO try to package 123elf https://github.com/taviso/123elf
        # TODO are there better choices than tran for quick transfer?
        tran
        # TODO how can I integrate this with caldav/sabre and org-cal
        # TODO should I use abook with contact server: https://abook.sourceforge.io/
        calcure
        # TODO build https://github.com/darrenburns/posting
        # TODO build https://github.com/ulissesf/qmassa
        # TODO should I try out canard + journalist?
        # TODO or https://github.com/veeso/tuifeed
        otree
        ttysvr
        sssnake
        # TODO https://github.com/hpjansson/chafa
        theattyr
        # TODO build https://github.com/ChangqingW/SeqSizzle
        # TODO build https://github.com/ShenMian/tracker

        # Language
        duden
        urban-cli

        # TODO how do these two compare
        zathura
        tdf
        # TODO how is this different from fd or emacs builtins?
        docfd

        # Weather
        mousam
        tenki
        wego
        wthrr

        # Keyboard layouts
        ngrrram
        # TODO fix this project!
        # NOTE https://github.com/Yvee1/hascard
        # NOTE https://github.com/callum-oakley/gotta-go-fast
        # haskellPackages.thock
        smassh
        thokr
        # TODO build https://github.com/akgondber/typing-game-cli
        # TODO build https://github.com/AnirudhG07/Typeinc

        # colemak-dh
        # TODO switch for colemak/colemak-dh layout

        localsend

        # TODO should I get the score submission and multiplayer AppImage?
        # osu-lazer
        # osu-lazer-bin

        # Haskell
        # TODO haskellPackages.bhoogle

        # Hacking
        armitage
        metasploit
        flawz
        # TODO build https://github.com/pythops/oryx

        # browsers
        elinks
        lagrange-tui
        # NOTE see overlay above
        # ladybird
      ];
    };
  };
}
