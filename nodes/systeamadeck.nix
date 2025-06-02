{
  config,
  inputs,
  ...
}: {
  canivete.pkgs.allowUnfree = [
    "steam-run"
    "steam-jupiter-original"
    "steam-jupiter-unwrapped"
    "steam"
    "steamcmd"
    "steamdeck-hw-theme"
    "steam-original"
  ];
  flake.overlays.jovian = inputs.jovian.overlays.default;
  # TODO fix login screen where I can't sign in (enter or submit doesn't work lol)
  # TODO moonlight-qt for to use axolotl as gaming server
  # NOTE https://moonlight-stream.org/
  # NOTE add libplacebo and vulkan-headers for HDR support
  dotfiles.nodes.systeamadeck.system = {
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) getExe mkMerge toList;
  in {
    imports = [inputs.jovian.nixosModules.jovian];
    config = mkMerge [
      {
        # Essentials
        boot.initrd.availableKernelModules = ["nvme" "xhci_pci" "usbhid" "sdhci_pci"];
        boot.kernelModules = ["kvm-amd"];
        dotfiles.graphical.enable = true;
        dotfiles.graphical.sound.enable = true;
        environment.systemPackages = with pkgs; [maliit-keyboard maliit-framework];
        networking.networkmanager.enable = true;
      }
      {
        # Jovian Steam
        dotfiles.programs.steam.enable = true;
        jovian.devices.steamdeck = {
          enable = true;
          autoUpdate = true;
          enableGyroDsuService = true;
        };
        jovian.steam = {
          enable = true;
          autoStart = true;
          desktopSession = "plasma";
          user = config.canivete.meta.people.me;
        };
        services.displayManager.sddm.enable = false;
      }
      (mkMerge [
        {
          # Decky Loader
          # TODO do I need to extract mura correction images?
          # NOTE https://github.com/Jovian-Experiments/Jovian-NixOS/issues/227
          # NOTE https://github.com/Jovian-Experiments/Jovian-NixOS/pull/229
          jovian.decky-loader = {
            enable = true;
            package = pkgs.decky-loader-prerelease;
            # TODO go through all plugins!
            plugins = {
              animation-changer.enable = true;
              css-loader.enable = true;
              game-theme-music.enable = true;
              game-theme-music.settings.settings = {
                defaultMuted = false;
                volume = 0.52;
                # TODO find or host a lasting invidious instance
                # invidiousInstance = "https" + "://" + "invidious.jing.rocks";
              };
              hltb.enable = true;
              vibrant-deck.enable = true;
            };
          };
        }
        {
          # Volume Boost
          jovian.decky-loader.extraPackages = [pkgs.pulseaudio];
          jovian.decky-loader.plugins.volume-boost.enable = true;
          services.pipewire.extraConfig.pipewire-pulse."11-decky-volume-boost"."pulse.cmd" = toList {
            cmd = "load-module";
            args = "module-native-protocol-tcp auth-anonymous=true";
          };
          systemd.services.decky-loader.environment.PULSE_SERVER = "tcp:127.0.0.1:4713";

          # TODO minimize security surface with cookie
          # environment.etc."pulse/client.conf".text = "cookie-file = /home/${config.canivete.meta.people.me}/.config/pulse/cookie";
        }
      ])
      {
        # Games
        home-manager.sharedModules = toList ({
          config,
          lib,
          pkgs,
          ...
        }: {
          config = mkMerge [
            {
              # World of Warcraft
              dotfiles.programs.steam.external.manual."Battle.Net".shortcut.exe = pkgs.fetchurl {
                name = "Battle.net-Setup.exe";
                url = "https://downloader.battle.net/download/getInstaller?os=win&installer=Battle.net-Setup.exe";
                hash = "sha256-FVeo035liq7s4MGpKp0yeVP1h/OkSnsQri55g6TQk+8=";
                executable = true;
              };

              # TODO modules
              # TODO better installation method
              # TODO build from source
              home.activation.wow-console-port = let
                ConsolePort = pkgs.fetchzip {
                  name = "ConsolePort-2.9.27";
                  url = "https://github.com/seblindfors/ConsolePort/releases/download/2.9.27/ConsolePort-2.9.27.zip";
                  hash = "sha256-5PWb+W572pdgMb3mvHDbSxMnS9bT+KLdLi7jrhpIsVg=";
                  stripRoot = false;
                };
                AddOns = pkgs.buildEnv {
                  name = "AddOns";
                  paths = [ConsolePort];
                };
              in
                lib.hm.dag.entryAfter ["writeBoundary"] ''
                  appid=$(${getExe pkgs.nostatoo} list-non-steam-games | ${pkgs.gawk}/bin/awk -F': ' '/Battle.Net/ {print $2}')
                  dest="${config.home.homeDirectory}/.local/share/Steam/steamapps/compatdata/$appid/pfx/drive_c/Program Files (x86)/World of Warcraft/_retail_/Interface/AddOns"
                  mkdir -p "$(dirname "$dest")"
                  ln -sfn ${AddOns} "$dest"
                '';
            }
            {
              # Runescape
              dotfiles.programs.steam.external.runescape = {
                rscplus.enable = true;
                # TODO fix this build and reactivate
                #    > /build/nuget.e1hUB6/fallback/avalonia/11.0.10/buildTransitive/AvaloniaBuildTasks.targets(81,5): error MSB4018: The "GenerateAvaloniaResourcesTask" task failed unexpectedly. [/build/source/Glitonea/Glitonea.csproj]
                #    > /build/nuget.e1hUB6/fallback/avalonia/11.0.10/buildTransitive/AvaloniaBuildTasks.targets(81,5): error MSB4018: System.IO.IOException: The process cannot access the file '/build/source/Glitonea/obj/Release/netstandard2.0/Avalonia/resources' because it is being used by another process. [/build/source/Glitonea/Glitonea.csproj]
                saradomin.enable = false;
                runelite.enable = true;
                hdos.enable = true;
              };
            }
            {
              # Consoles
              dotfiles.programs.steam.external = {
                chiaki.enable = true;
                # TODO convert these to a service that can manage them dynamically through rclone
                consoles = {
                  NES.programs = [
                    "Legend of Zelda, The (USA)"
                    "Zelda II - The Adventure of Link (USA)"
                  ];
                  SNES.programs = [
                    "Legend of Zelda, The - A Link to the Past (USA)"
                    "Chrono Trigger (USA)"
                    "Shin Megami Tensei (Japan)"
                    "Shin Megami Tensei II (Japan)"
                    "Shin Megami Tensei if... (Japan)"
                    "Rudra no Hihou (Japan)"
                  ];
                  GB.programs = [
                    "Legend of Zelda, The - Link's Awakening (USA, Europe)"
                  ];
                  GBC.programs = [
                    "Legend of Zelda, The - Link's Awakening DX (USA, Europe) (SGB Enhanced) (GB Compatible)"
                    "Legend of Zelda, The - Oracle of Seasons (USA, Australia)"
                    "Legend of Zelda, The - Oracle of Ages (USA, Australia)"
                  ];
                  GBA.programs = [
                    "Legend of Zelda, The - A Link to the Past & Four Swords (USA)"
                    "Legend of Zelda, The - The Minish Cap (USA)"
                    "Kingdom Hearts - Chain of Memories (USA)"
                  ];
                  N64.programs = [
                    "Legend of Zelda, The - Ocarina of Time (USA)"
                    "Legend of Zelda, The - Majora's Mask (USA)"
                    "Paper Mario (USA)"
                  ];
                  GC.programs = [
                    "Legend of Zelda, The - The Wind Waker (USA)"
                    "Legend of Zelda, The - Four Swords Adventures (USA)"
                    "Legend of Zelda, The - Twilight Princess (USA)"
                    "Paper Mario - The Thousand-Year Door (USA)"
                  ];
                  Wii.programs = [
                    "Legend of Zelda, The - Skyward Sword (USA) (En,Fr,Es)"
                    "Super Paper Mario (USA)"
                  ];
                  DS.programs = [
                    "Legend of Zelda, The - Phantom Hourglass (USA) (En,Fr,Es)"
                    "Legend of Zelda, The - Spirit Tracks (USA, Australia) (En,Fr,Es)"
                    "World Ends with You, The (USA)"
                    "Kingdom Hearts - Re-coded (USA) (En,Fr,Es)"
                    "Kingdom Hearts - 358-2 Days (USA) (En,Fr)"
                    "Shin Megami Tensei - Strange Journey (USA)"
                  ];
                  "3DS".programs = [
                    "Legend of Zelda, The - A Link Between Worlds (USA) (En,Fr,Es)"
                    "Legend of Zelda, The - Tri Force Heroes (USA) (En,Fr,Es)"
                    "Kingdom Hearts 3D - Dream Drop Distance (USA) (En,Fr)"
                    "Paper Mario - Sticker Star (USA) (En,Fr,Es)"
                    "Shin Megami Tensei IV (USA)"
                    "Shin Megami Tensei IV - Apocalypse (USA)"
                  ];
                  WiiU.programs = [
                    "Paper Mario - Color Splash (USA) (En,Fr,Es)"
                  ];
                  PS1.bios = ["ps-41a"];
                  PS1.programs = [
                    "Chrono Cross (USA) (Disc 1)"
                    "Chrono Cross (USA) (Disc 2)"
                    "Legacy of Kain - Soul Reaver (USA)"
                    "Persona (USA)"
                    "Persona 2 - Tsumi - Innocent Sin (Japan)"
                    "Persona 2 - Eternal Punishment (USA)"
                  ];
                  PS2.programs = [
                    "Kingdom Hearts (USA)"
                    "Kingdom Hearts II (USA)"
                    "Shin Megami Tensei - Nocturne (USA)"
                    "Shin Megami Tensei - Persona 3 (USA)"
                    "Shin Megami Tensei - Persona 4 (USA)"
                    "Shin Megami Tensei - Digital Devil Saga (USA)"
                    "Shin Megami Tensei - Digital Devil Saga 2 (USA)"
                    "Ookami (USA)"
                  ];
                  PS3.programs = [
                    "Persona 5 (USA)"
                  ];
                  PSP.programs = [
                    "Kingdom Hearts - Birth by Sleep (USA) (En,Fr,Es)"
                  ];
                  XB.programs = [
                    "Shin Megami Tensei - Nine (Japan)"
                  ];

                  # XB360.wrapper = pkgs.xenia-canary;
                  # TODO figure out if this is even possible anymore
                  # Switch.wrapper = pkgs.ryujinx;
                  # TODO need to build this
                  # NOTE https://github.com/NixOS/nixpkgs/compare/master...henkery:nixpkgs:vita3k
                  # PSV.wrapper = pkgs.vita3k;
                };
              };
            }
          ];
        });
      }
    ];
  };
}
