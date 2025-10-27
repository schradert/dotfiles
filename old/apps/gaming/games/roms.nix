{lib, ...}: let
  inherit (lib) concat flip filterAttrs forEach getAttr getExe length literalExpression mkDefault mapAttrsToList mapAttrs mkEnableOption mkPackageOption mkOption mkIf recursiveUpdate escapeURL isString isAttrs throw types pipe;
in {
  flake.overlays.roms = final: _: {
    myrient = let
      builderFor = consolePaths: attrs:
        flip final.callPackage {} ({
          stdenv,
          fetchzip,
        }:
          stdenv.mkDerivation (finalAttrs:
            flip recursiveUpdate attrs {
              src = fetchzip {
                inherit (finalAttrs) name hash;
                url = "https://myrient.erista.me/files/${escapeURL consolePaths.${finalAttrs.console}}/${escapeURL finalAttrs.name}.zip";
                stripRoot = false;
              };
              installPhase = ''
                mkdir -p $out
                cp -R ./* $out
              '';
            }));
      buildWith = builder: let
        buildAttrs = hashOrAttrs:
          if isString hashOrAttrs
          then {hash = hashOrAttrs;}
          else if isAttrs hashOrAttrs
          then hashOrAttrs
          else throw "Argument of buildAttrs must be a string or attrset";
        wrappedBuilder = console: name: hashOrAttrs: builder (buildAttrs hashOrAttrs // {inherit console name;});
      in
        mapAttrs (flip pipe [wrappedBuilder mapAttrs]);
    in {
      # ROMS
      buildROM = builderFor {
        NES = "No-Intro/Nintendo - Nintendo Entertainment System (Headered)";
        SNES = "No-Intro/Nintendo - Super Nintendo Entertainment System";
        GB = "No-Intro/Nintendo - Game Boy";
        GBC = "No-Intro/Nintendo - Game Boy Color";
        GBA = "No-Intro/Nintendo - Game Boy Advance";
        N64 = "No-Intro/Nintendo - Nintendo 64 (BigEndian)";
        GC = "Redump/Nintendo - GameCube - NKit RVZ [zstd-19-128k]";
        Wii = "Redump/Nintendo - Wii - NKit RVZ [zstd-19-128k]";
        DS = "No-Intro/Nintendo - Nintendo DS (Decrypted)";
        "3DS" = "No-Intro/Nintendo - Nintendo 3DS (Decrypted)";
        WiiU = "Redump/Nintendo - Wii U - WUX";
        PS1 = "Redump/Sony - PlayStation";
        PS2 = "Redump/Sony - PlayStation 2";
        PS3 = "Redump/Sony - PlayStation 3";
        PSP = "Redump/Sony - PlayStation Portable";
        XB = "Redump/Microsoft - Xbox";
      };
      roms = buildWith final.myrient.buildROM {
        # Zelda
        NES."Legend of Zelda, The (USA)" = "sha256-1TKw2T8eCmHEziSemCYa4IahcZaVntQ+6pkR/ek7+LU=";
        NES."Zelda II - The Adventure of Link (USA)" = "sha256-8HoSE3o3f+WTFTiYXSJrZn3giM0So82s7SHhsd1mOvQ=";
        SNES."Legend of Zelda, The - A Link to the Past (USA)" = "sha256-ZAUiaS9oVH4CHO4QYK967yT9oP++oXpnHSMyEScBci4=";
        GB."Legend of Zelda, The - Link's Awakening (USA, Europe)" = "sha256-TenE6MVSQVVlUpiFeOdNQhr1dSpqBB/pYluCItJs7/0=";
        GBC."Legend of Zelda, The - Link's Awakening DX (USA, Europe) (SGB Enhanced) (GB Compatible)" = "sha256-ctWvibtAzqgMKJJGD8qq1mmLeBpCXv632HQTLde6Ac8=";
        GBC."Legend of Zelda, The - Oracle of Seasons (USA, Australia)" = "sha256-H5l1CBjzsTmBkkyKNh59Ek0rpFbnaLrlosZ/C+huDHs=";
        GBC."Legend of Zelda, The - Oracle of Ages (USA, Australia)" = "sha256-8kSq9xl7yBUgblutzdlJ/1yLveHoihfevQ6Se3AL2rg=";
        GBA."Legend of Zelda, The - A Link to the Past & Four Swords (USA)" = "sha256-CeG/52pO9/dbX+rkk/ZNxO8PaSfB9oEFfwlaSI/kxGc=";
        GBA."Legend of Zelda, The - The Minish Cap (USA)" = "sha256-T/3BKvm5n48ChnRfzT1V9O/ldaP9QSr9Dd46k/UfVqc=";
        N64."Legend of Zelda, The - Ocarina of Time (USA)" = "sha256-vTw1C5atHD3CiPaXMHN/UUa3PszQ0HUktB7dnBIDsqE=";
        N64."Legend of Zelda, The - Majora's Mask (USA)" = "sha256-3MBgYqxFHATNmdC25F80OHEu4xRh2m5xdOZk5VXbv7o=";
        GC."Legend of Zelda, The - The Wind Waker (USA)" = "sha256-0a7vzjBnFyI3QaZWK/3hQEQ6Y4d0mQ1MBm5fbFWz5Ig=";
        GC."Legend of Zelda, The - Four Swords Adventures (USA)" = "sha256-u7boLGoP0h5rz4rKv+1UeKFYaFvSyY/YgoPC4JNQb3E=";
        GC."Legend of Zelda, The - Twilight Princess (USA)" = "sha256-ts5z+pdFYLI/ws3YjsJ0D1Nr39Vue6CWleyEqCSmGxo=";
        Wii."Legend of Zelda, The - Skyward Sword (USA) (En,Fr,Es)" = "sha256-2eiYTnmL5obqqFsbDZ59l3StzL42jaKhKdZeKZRX3tk=";
        DS."Legend of Zelda, The - Phantom Hourglass (USA) (En,Fr,Es)" = "sha256-Gs/8B73lmV6Dbn9IQe0kia2jHwnu3Ap8Uj8rNJAt4lM=";
        DS."Legend of Zelda, The - Spirit Tracks (USA, Australia) (En,Fr,Es)" = "sha256-Jc8ZHP13i7jo0rjyoX6k80eglq1e6iLSZicN5G607rw=";
        "3DS"."Legend of Zelda, The - A Link Between Worlds (USA) (En,Fr,Es)" = "sha256-o0AMEhC7YO6wT3SHZNkT7cTSYPJQnPdmcj2/kWmLPHM=";
        "3DS"."Legend of Zelda, The - Tri Force Heroes (USA) (En,Fr,Es)" = "sha256-IJh0XT6Sp/f37GoiyRvJ+uAYOQlbRJyThvwHJViXKTs=";

        # Kingdom Hearts
        PS2."Kingdom Hearts (USA)" = "sha256-5oDFgaPuqhJVmL7bWBFMiF0bWOA9ZYmaE4mq1InkpjA=";
        GBA."Kingdom Hearts - Chain of Memories (USA)" = "sha256-gr72LpmqXnLaFRceCY+jKBlwre8BBrEwC3hNLqEnX/o=";
        PS2."Kingdom Hearts II (USA)" = "sha256-OLGChGzEquaWkPLgILKW4sLmAYIJYtFM3yWC5MfBSZM=";
        DS."Kingdom Hearts - Re-coded (USA) (En,Fr,Es)" = "sha256-Na0QpzePjQUq7tghcE0vDj9OyKXFuCVPVxj0FVIobVM=";
        DS."Kingdom Hearts - 358-2 Days (USA) (En,Fr)" = "sha256-7uxCIOP4ZCQg96cuRf518fHBv5hiYkjrmNX07W6y4BE=";
        PSP."Kingdom Hearts - Birth by Sleep (USA) (En,Fr,Es)" = "sha256-ude8IJkNFO/wHIsiyf9Jm2z9gXCZJxLssHT1tw82eCM=";
        "3DS"."Kingdom Hearts 3D - Dream Drop Distance (USA) (En,Fr)" = "sha256-LBLoU/4xAFaJUsKcR08TNOpaf62zFBC5GCpWjN/2rcA=";

        # Paper Mario
        N64."Paper Mario (USA)" = "sha256-HHXH8d06Y8/lsc3RIGk97DCXqQo8Er+HMvlKn8g/WVk=";
        GC."Paper Mario - The Thousand-Year Door (USA)" = "sha256-Vg+5UijLYiOD668+TWxAPKjtmtdq8saOdcS53Hes7zk=";
        Wii."Super Paper Mario (USA)" = "sha256-8HmOEViKgSoVL0fAU0r4dc+5Eevjp5iLV+HCEfGVIsM=";
        "3DS"."Paper Mario - Sticker Star (USA) (En,Fr,Es)" = "sha256-3gqv86j52Ybw4w8U0zZomjdmkTjaaGGuFkEhxbqLu4E=";
        WiiU."Paper Mario - Color Splash (USA) (En,Fr,Es)" = "sha256-7omE0HV3CfFH0pLWg6ohDyCTxyrvh92b/vjW+2Vx3EU=";

        # Chrono
        SNES."Chrono Trigger (USA)" = "sha256-2Zfm5Qtvz7Cfd2emBSdOkaj9m8uoT/yu04AIbvgLMxA=";
        PS1."Chrono Cross (USA) (Disc 1)" = "sha256-WY86n4nku+qxuRm2Do2lMGTsh/sBc8b9JZ7Esb8CCu0=";
        PS1."Chrono Cross (USA) (Disc 2)" = "sha256-MaQ/iII4woRV+Xc4R+NqysVgsyLjnVteP2Ilb/wg8U0=";

        # Shin Megami Tensei
        SNES."Shin Megami Tensei (Japan)" = "sha256-AA4hKYyLNyBmJ3XvvJvV7r+wHOUGm3zCBn9QNuoxQkg=";
        SNES."Shin Megami Tensei II (Japan)" = "sha256-tGiY+pBNfTaUys/WlOwl5E74sscGH2VUL08Bbu8UGfk=";
        SNES."Shin Megami Tensei if... (Japan)" = "sha256-aFT+juKzvum5n6uu+FTpXzh0jli5VOAADAYRJhiijWo=";
        XB."Shin Megami Tensei - Nine (Japan)" = "sha256-9jelCpiZ3CwPvAxrs1OTolsPC5F45Hx6cTeEqDJ8L6Q=";
        PS2."Shin Megami Tensei - Nocturne (USA)" = "sha256-8NMyKVYcb9Yp7RehrTmGSaaNOXHacEQCXrUZmzbkU7U=";
        DS."Shin Megami Tensei - Strange Journey (USA)" = "sha256-LRjEgC29WxsSOBCHjgGofD3OoZefJGADN06kK1KAt4w=";
        "3DS"."Shin Megami Tensei IV (USA)" = "sha256-x4usANn2S2Hi+Ky2OpFRUbWxN7ZV2lKlAEGiDZWHWHc=";
        "3DS"."Shin Megami Tensei IV - Apocalypse (USA)" = "sha256-frwa3334G1jisL/Z2L1o/9kZrym/oXOP0dkBh8W3WYQ=";

        # Persona
        PS1."Persona (USA)" = "sha256-VCa7nzsmwz4xR1nAf9/kHrsjWvmPlE1DJ7rAjIi/1Nc=";
        PS1."Persona 2 - Tsumi - Innocent Sin (Japan)" = "sha256-pLrzTsYfjMF4n4/zzN2G61U3kzx/U89rKi8mmB086oE=";
        PS1."Persona 2 - Eternal Punishment (USA)" = "sha256-kP9/lcPTdb+zS1Atq1gDPfi6yPku7lcFUAjw5GP/kPg=";
        PS2."Shin Megami Tensei - Persona 3 (USA)" = "sha256-5YbetmIcyJJ6zz8LKij9AsY82OjDqTmsY9mPmXVgmCs=";
        PS2."Shin Megami Tensei - Persona 4 (USA)" = "sha256-NNz9DOF9isQWEOy0Jr3dJNn+omQxLihvffNSjpbCEqo=";
        PS3."Persona 5 (USA)" = "sha256-yz/b69C+qJhkylX6C834Ly0UjsOiwd1U5pXYDiGwKE0=";

        # Digital Devil Saga
        PS2."Shin Megami Tensei - Digital Devil Saga (USA)" = "sha256-t/0zSn95uweU4/ABRIMNIaKD5FMRNbnYM5Ows5WdwOc=";
        PS2."Shin Megami Tensei - Digital Devil Saga 2 (USA)" = "sha256-ZT15hSFxSadiqHFayM4nYmErfueoKXQBucdZ19wCq+U=";

        # Turok
        N64."Turok - Dinosaur Hunter (USA)" = "";
        N64."Turok 2 - Seeds of Evil (USA)" = "";
        N64."Turok 3 - Shadow of Oblivion (USA)" = "";
        GC."Turok - Evolution (USA)" = "";

        # Team Ico
        PS2."Ico (USA)" = "";
        PS2."Shadow of the Colossus (USA)" = "";

        # Jak and Daxter
        PS2."Jak and Daxter - The Precursor Legacy (USA) (En,Fr,De,Es,It)" = "";
        PS2."Jak II (USA) (En,Ja,Fr,De,Es,It,Ko) (v2.01)" = "";
        PS2."Jak 3 (USA) (En,Fr,De,Es,It,Pt,Ru)" = "";
        PSP."Daxter (USA) (En,Fr,De,Es,It)" = "";

        # Crash Bandicoot
        PS1."Crash Bandicoot (USA)" = "";
        PS1."Crash Bandicoot 2 - Cortex Strikes Back (USA)" = "";
        PS1."Crash Bandicoot - Warped (USA)" = "";
        PS1."CTR - Crash Team Racing (USA)" = "";
        PS1."Crash Bash (USA)" = "";

        # Onimusha
        # PS2."Onimusha: Warlords"
        # PS2."Onimusha 2: Samurai's Destiny"
        # PS2."Onimusha 3: Demon Siege"
        # PS2."Onimusha: Dawn of Dreams"

        # Uncharted
        # TODO these are too large right now to handle this way...
        # PS3."Uncharted - Drake's Fortune (USA) (En,Fr,De,Es,It,Nl,Pt,Sv,No,Da,Fi)" = "";
        # PS3."Uncharted 2 - Among Thieves (USA) (En,Fr,Es)" = "";
        # PS3."Uncharted 3 - Drake's Deception (USA) (En,Fr,Es,Pt)" = "";
        # TODO support PlayStation Vita
        # PSV."Uncharted Golden Abyss" = "";

        # Independent
        SNES."Rudra no Hihou (Japan)" = "sha256-Vc8C6H3iW6TWoNbmEErqobV/ZuHZwdTpVysFH/c9Cyw=";
        PS1."Legacy of Kain - Soul Reaver (USA)" = "sha256-oL7UUbxwQFFbHYpUgUZ/lf2YTvG26b6Cvaud5CkOXD0=";
        DS."World Ends with You, The (USA)" = "sha256-XJnoO804J0ArJmy7lSZzuKeultkCgjoM/4Qmn3563wg=";
        PS2."Ookami (USA)" = "";
        N64."GoldenEye 007 (USA)" = "";
        N64."Perfect Dark (USA)" = "";

        # Not Matching
        SNES."Illusion of Gaia" = "";
        SNES."Live A Live" = "";
        SNES."Star Ocean" = "";
        # Lunar: The Silver Star on Sega Genesis + Mega-CD
        # Phantasy Star IV: The End of the Millennium for Sega Genesis
        "3DS"."The Alliance Alive" = "";
        PS1."Legend of Legaia" = "";
        SNES.EarthBound = "";
        GBA."Golden Sun" = "";
        WiiU."Xenoblade Chronicles X" = "";
        PS1."Jade Cocoon: Story of the Tamamayu" = "";
        PS1."Vandal Hearts" = "";
        PS1."Valkyrie Profile" = "";
        PS1."Breath of Fire III" = "";
        PS1."Suikoden II" = "";
        PS1.Xenogears = "";
        PS1."Vagrant Story" = "";
        PS1."Final Fantasy Tactics" = "";
        PS2.Yakuza = "";
        PS2."Yakuza 2" = "";
        PS3."Yakuza 3" = "";
        PS3."Yakuza 4" = "";
        PS3."Yakuza 5" = "";
        # Legend of Heroes and Trails series!
        PS3."The Legend of Heroes: Trails of Cold Steel" = "";
        #PSV."Ys VIII: Lacrimosa of Dana" = "";
        # Ys: The Oath in Felghana on Windows
        # Ys series!
        # GC."Tales of Symphonia" = "";
        # XB360."Tales of Vesperia" = "";
        # Tales series!
        # PS2."Shadow Hearts: Covenant" = "";
        # Wild Arms series!
        # SNES."Secret of Mana" = "";
        # Spyro series!
        # Dragon Quest series!
        # XB360."Hydro Thunder Hurricane" = "";
      };

      # BIOS
      buildBIOS = builderFor {
        PS1 = "Redump/Sony - PlayStation - BIOS Images";
      };
      bios = buildWith final.myrient.buildBIOS {
        PS1.ps-41a = "sha256-xrIXKXbsnEYB7h1R3gg80Tua5sEMhxDX4083RVO7j9I=";
      };
    };
  };
  dotfiles.devenv.git-hooks.hooks.lychee.toml.exclude = ["https://myrient.erista.me/*"];
  dotfiles.home-manager = {
    config,
    pkgs,
    ...
  }: let
    inherit (types) str nullOr attrsOf package listOf either submodule;
    inherit (config.dotfiles.programs.steam) external;
    ini = pkgs.formats.ini {};
  in {
    options.dotfiles.programs.steam.external = {
      enable = mkEnableOption "management of external games in steam" // {default = config.dotfiles.graphical.enable;};
      directory = mkOption {
        type = str;
        default = "Games/ROMs";
      };
      retroarch.package = mkPackageOption pkgs "retroarch" {};
      retroarch.settings = mkOption {
        inherit (ini) type;
        default = {};
        description = "Contents of retroarch.cfg";
      };
      consoles = mkOption {
        type = attrsOf (submodule {
          options.retroarch = mkEnableOption "corresponding retroarch library";
          options.wrapper = mkOption {
            type = nullOr package;
            default = null;
            description = "Wrapper program like an emulator. If retroarch is set, this is the libretro core/library. Null usually corresponds to manual entries.";
          };
          options.programs = mkOption {
            type = listOf (either str package);
            default = [];
            description = "Name of existing package or a new package to run with the wrapper";
          };
          options.bios = mkOption {
            type = listOf (either str package);
            default = [];
            description = "Name of existing BIOS package or a new package to provide to the wrapper";
          };
        });
        default = {};
        example = literalExpression "{ GBC.programs = [\"Legend of Zelda, The - Oracle of Ages (USA, Australia)\" pkgs.myrient.roms.GB.\"Legend of Zelda, The - Link's Awakening (USA, Europe)\"]; }";
        description = "ROMs to build and install for each console. The name should be the name of file hosted on myrient.erista.me";
      };
    };
    config = mkIf external.enable {
      dotfiles.programs.steam.external = {
        manual = {
          RetroArch.shortcut.exe = getExe external.retroarch.package;
          Cemu.shortcut.exe = getExe pkgs.cemu;
          DuckStation.shortcut.exe = getExe pkgs.duckstation;
          RPCS3.shortcut.exe = getExe pkgs.rpcs3;
          Xemu.shortcut.exe = getExe pkgs.xemu;
        };
        retroarch.package = pkgs.retroarch.withCores (_:
          pipe external.consoles [
            (filterAttrs (_: getAttr "retroarch"))
            (mapAttrsToList (_: getAttr "wrapper"))
          ]);
        # TODO figure out passing secrets
        # TODO how to merge config with defaults?
        retroarch.settings = {
          input_joypad_driver = "sdl2";
          rewind_enable = true;
          input_rewind_btn = 19;
          input_toggle_fast_forward_btn = 18;
          cheevos_enable = true;
          cheevos_username = "retoro";
          cheevos_password = "!!CHEEVOS_PASSWORD!!";
          cheevos_unlock_sound_enable = true;
          cheevos_auto_screenshot = true;
          cheevos_badges_enable = true;
          cheevos_start_active = true;
        };
        consoles = {
          NES.retroarch = mkDefault true;
          NES.wrapper = mkDefault pkgs.libretro.fceumm;
          NES.parsers."Nintendo NES - Retroarch - FCEUmm".overrides.romDirectory = mkDefault "\${romsdirglobal}\${/}NES";
          SNES.retroarch = mkDefault true;
          SNES.wrapper = mkDefault pkgs.libretro.bsnes-hd;
          SNES.parsers."Nintendo SNES - Retroarch - bsnes-hd" = mkDefault {
            preset = mkDefault "Nintendo SNES - Retroarch - Beetle bsnes";
            overrides.romDirectory = mkDefault "\${romsdirglobal}\${/}SNES";
            overrides.executableArgs = mkDefault "-L \${os:win|cores|\${os:mac|\${racores}|\${os:linux|\${racores}}}}\${/}bsnes_hd_beta_libretro.\${os:win|dll|\${os:mac|dylib|\${os:linux|so}}} \\\"\${filePath}\\\"";
          };
          GB.retroarch = mkDefault true;
          GB.wrapper = mkDefault pkgs.libretro.sameboy;
          GB.parsers."Nintendo GameBoy - Retroarch - SameBoy".overrides.romDirectory = mkDefault "\${romsdirglobal}\${/}GB";
          GBC.retroarch = mkDefault true;
          GBC.wrapper = mkDefault pkgs.libretro.sameboy;
          GBC.parsers."Nintendo GameBoy Color - Retroarch - SameBoy".overrides.romDirectory = mkDefault "\${romsdirglobal}\${/}GBC";
          GBA.retroarch = mkDefault true;
          GBA.wrapper = mkDefault pkgs.libretro.mgba;
          GBA.parsers."Nintendo GameBoy Advance - Retroarch - mGBA".overrides.romDirectory = mkDefault "\${romsdirglobal}\${/}GBA";
          N64.retroarch = mkDefault true;
          N64.wrapper = mkDefault pkgs.libretro.mupen64plus;
          N64.parsers."Nintendo 64 - Retroarch - Mupen64Plus Next".overrides.romDirectory = mkDefault "\${romsdirglobal}\${/}N64";
          GC.retroarch = mkDefault true;
          GC.wrapper = mkDefault pkgs.libretro.dolphin;
          GC.parsers."Nintendo GameCube - Retroarch - Dolphin".overrides.romDirectory = mkDefault "\${romsdirglobal}\${/}GC";
          Wii.retroarch = mkDefault true;
          Wii.wrapper = mkDefault pkgs.libretro.dolphin;
          Wii.parsers."Nintendo Wii - Retroarch - Dolphin".overrides.romDirectory = mkDefault "\${romsdirglobal}\${/}Wii";
          DS.retroarch = mkDefault true;
          DS.wrapper = mkDefault pkgs.libretro.melonds;
          DS.parsers."Nintendo DS - Retroarch - melonDS".overrides.romDirectory = mkDefault "\${romsdirglobal}\${/}DS";
          "3DS".retroarch = mkDefault true;
          "3DS".wrapper = mkDefault pkgs.libretro.citra;
          "3DS".parsers."Nintendo 3DS - Retroarch - Citra".overrides.romDirectory = mkDefault "\${romsdirglobal}\${/}3DS";
          WiiU.wrapper = pkgs.cemu;
          WiiU.parsers."Nintendo 3DS - Cemu (WUD/WUX)".overrides = {
            romDirectory = mkDefault "\${romsdirglobal}\${/}WiiU";
            executable.path = mkDefault (getExe pkgs.cemu);
          };
          # TODO configure swanstation
          PS1.wrapper = mkDefault pkgs.duckstation;
          PS1.parsers."Sony PlayStation - DuckStation".overrides = mkDefault {
            romDirectory = mkDefault "\${romsdirglobal}\${/}PS1";
            executable.path = mkDefault (getExe pkgs.duckstation);
          };
          PS2.retroarch = mkDefault true;
          PS2.wrapper = mkDefault pkgs.libretro.pcsx2;
          PS2.parsers."Sony PlayStation 2 - Retroarch - PCSX2".overrides.romDirectory = mkDefault "\${romsdirglobal}\${/}PS2";
          PS3.wrapper = mkDefault pkgs.rpcs3;
          PS3.parsers."Sony PlayStation 3 - RPCS3 (Extracted ISO)".overrides = mkDefault {
            romDirectory = mkDefault "\${romsdirglobal}\${/}PS3";
            executable.path = mkDefault (getExe pkgs.rpcs3);
          };
          PSP.retroarch = mkDefault true;
          PSP.wrapper = mkDefault pkgs.libretro.ppsspp;
          PSP.parsers."Sony PlayStation Portable - Retroarch - PPSSPP".overrides.romDirectory = mkDefault "\${romsdirglobal}\${/}PSP";
          XB.wrapper = mkDefault pkgs.xemu;
          XB.parsers."Microsoft Xbox - Xemu".overrides = mkDefault {
            romDirectory = mkDefault "\${romsdirglobal}\${/}XB";
            executable.path = mkDefault (getExe pkgs.xemu);
          };
        };
      };
      home.packages = pipe external.consoles [
        (filterAttrs (_: console: !console.retroarch && console.wrapper != null))
        (mapAttrsToList (_: getAttr "wrapper"))
        (concat [
          external.nostatoo
          external.srm.package
          external.retroarch.package

          # TODO fix build
          # NOTE canivete.pkgs.config.permittedInsecurePackages = ["freeimage-unstable-2021-11-01"];
          # pkgs.emulationstation-de
        ])
      ];
      # TODO configure emulator settings
      # home.activation.retroarch = lib.hm.dag.entryAfter ["writeBoundary"] ''
      #   install -D --mode 644 ${ini.generate "retroarch.cfg" external.retroarch.settings} "${config.home.homeDirectory}/.config/retroarch/retroarch.cfg"
      # '';
      home.file.${external.directory}.source = pipe external.consoles [
        (filterAttrs (_: console: length console.programs > 0))
        (mapAttrsToList (name: console: {
          inherit name;
          path = pkgs.buildEnv {
            inherit name;
            paths = forEach console.programs (
              nameOrPackage:
                if isString nameOrPackage
                then pkgs.myrient.roms.${name}.${nameOrPackage}
                else nameOrPackage
            );
          };
        }))
        (pkgs.linkFarm "SteamExternalPrograms")
      ];
      home.file."${builtins.dirOf external.directory}/BIOS".source = pipe external.consoles [
        (filterAttrs (_: console: length console.bios > 0))
        (mapAttrsToList (name: console: {
          inherit name;
          path = pkgs.buildEnv {
            inherit name;
            paths = forEach console.bios (
              nameOrPackage:
                if isString nameOrPackage
                then pkgs.myrient.bios.${name}.${nameOrPackage}
                else nameOrPackage
            );
          };
        }))
        (pkgs.linkFarm "SteamConsoleBIOS")
      ];
      home.file.".local/share/Cemu/keys.txt".source = pkgs.fetchurl {
        url = "https://drive.google.com/uc?id=1869wHy8omyBJVX7bnfLQ-nwsnW3d95V4";
        hash = "sha256-HQpqkrmgy/2o1zKcTb6UU37/Vro8BuvsB9bu8lLI874=";
      };
    };
  };
}
