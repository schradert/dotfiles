{
  config,
  inputs,
  nix,
  ...
}:
with nix; let
  inherit (config.canivete) root;
  sshOptions = ["ProxyJump=${config.dotfiles.domain}"];
  # Disko does not actually merge NixOS modules (major bummer!)
  # I have to use recursiveUpdate within the same module for all settings to be detected and used
  # NOTE https://github.com/nix-community/disko/issues/678
  # NOTE https://github.com/NixOS/nixpkgs/pull/284551
  disko.devices.disk.base = {
    device = "/dev/sda";
    type = "disk";
    content.type = "gpt";
    content.partitions = {
      ESP = {
        priority = 1;
        type = "EF00";
        size = "500M";
        content.type = "filesystem";
        content.format = "vfat";
        content.mountpoint = "/boot";
      };
      root = {
        priority = 2;
        end = "-1G";
        content.type = "filesystem";
        content.format = "ext4";
        content.mountpoint = "/";
      };
      swap = {
        size = "100%";
        content.type = "swap";
        content.discardPolicy = "both";
        content.resumeDevice = true;
      };
    };
  };
  lvmDisko = recursiveUpdate disko {
    devices.disk.base = {
      content.partitions.k8s = {
        priority = 3;
        end = "-1G";
        content.type = "lvm_pv";
        content.vg = "k8s";
      };
    };
    devices.lvm_vg.k8s.type = "lvm_vg";
  };
in {
  # TODO why the fuck do I have to keep doing this?
  perSystem.canivete.opentofu.workspaces.deploy.modules.install-override.resource.null_resource = {
    nixos_sirver_system_install.provisioner.local-exec.command = mkForce "echo";
    nixos_axolotl_system_install.provisioner.local-exec.command = mkForce "echo";
    nixos_bonobo_system_install.provisioner.local-exec.command = mkForce "echo";
    nixos_chinchilla_system_install.provisioner.local-exec.command = mkForce "echo";
    nixos_dingo_system_install.provisioner.local-exec.command = mkForce "echo";
    nixos_octopus_system_install.provisioner.local-exec.command = mkForce "echo";
    nixos_systeamadeck_system_install.provisioner.local-exec.command = mkForce "echo";
  };
  flake.overlays.jovian = inputs.jovian.overlays.default;
  flake.overlays.gamescope = final: prev: {
    umu = inputs.umu.packages.${prev.system}.umu.override {version = inputs.umu.shortRev;};
    kodi = prev.kodi.withPackages (ps: with ps; [invidious jellyfin netflix trakt]);
    # TODO might not be necessary given: https://github.com/NixOS/nixpkgs/blob/c31898adf5a8ed202ce5bea9f347b1c6871f32d1/pkgs/by-name/ga/gamescope/package.nix#L104
    gamescope = prev.gamescope.overrideAttrs (old: {nativeBuildInputs = old.nativeBuildInputs ++ [prev.git];});
  };
  canivete.deploy.nixos.nodes = {
    sirver = {
      install.host = "192.168.50.23";
      install.sshOptions = mkForce ["User=root"];
      target.sshOptions = sshOptions;
      profiles.system.module = {
        dotfiles.kubernetes.enable = true;
        dotfiles.kubernetes.root = true;
        dotfiles.devops.enable = true;
        disko = recursiveUpdate lvmDisko {
          devices.disk.base = {
            device = "/dev/disk/by-id/scsi-361866da05a3c260002ecf1a16170342b";
            content.partitions.root.end = "-1T";
          };
        };
        boot.initrd.availableKernelModules = ["ehci_pci" "megaraid_sas" "usbhid"];
        boot.kernelModules = ["kvm-intel"];
      };
    };
    axolotl = {
      install.host = "192.168.50.250";
      build.host = root;
      build.sshOptions = sshOptions;
      profiles.system.sshProtocol = "ssh";
      profiles.system.module = {pkgs, ...}: {
        dotfiles.graphical.enable = true;
        dotfiles.graphical.monitors = true;
        dotfiles.graphical.sound.enable = true;
        dotfiles.graphical.hyprland.enable = true;
        dotfiles.kubernetes.enable = true;
        boot.initrd.availableKernelModules = ["xhci_pci" "nvme" "rtsx_pci_sdmmc"];
        disko = recursiveUpdate lvmDisko {
          devices.disk.base = {
            device = "/dev/disk/by-id/nvme-SPCC_M.2_PCIE_SSD_30012119169";
            content.partitions.root.end = "-101G";
          };
        };
        home-manager.sharedModules = toList {
          dotfiles.email = true;
          dotfiles.macchina.networkInterface = "enp0s31f6";
          dotfiles.programs.steam.external = {
            enable = true;
            srm.userAccounts = ["supertriggy"];
            runescape.runelite.enable = true;
          };
        };

        location.latitude = 37.8;
        location.longitude = -122.4;

        # Gaming
        programs.steam.enable = true;
        programs.steam.extraCompatPackages = with pkgs; [proton-ge-bin steamtinkerlaunch steam-play-none];
        programs.steam.protontricks.enable = true;
        programs.gamemode.enable = true;
        programs.gamemode.enableRenice = true;

        # Deactivate auto sleep
        services.logind.lidSwitch = "ignore";
        services.xserver.videoDrivers = ["displaylink" "modesetting"];
        systemd.targets = {
          sleep.enable = false;
          suspend.enable = false;
          hibernate.enable = false;
          hybrid-sleep.enable = false;
        };
      };
    };
    bonobo = {
      install.host = "192.168.50.142";
      build.sshOptions = sshOptions;
      profiles.system.module = {
        dotfiles.kubernetes.enable = true;
        boot.initrd.availableKernelModules = ["xhci_pci" "usbhid"];
        disko = recursiveUpdate lvmDisko {
          devices.disk.base = {
            device = "/dev/disk/by-id/ata-Micron_1100_SATA_256GB_165015496CBD";
            content.partitions.root.end = "-51G";
          };
        };
      };
    };
    chinchilla = {
      install.host = "192.168.50.85";
      build.sshOptions = sshOptions;
      profiles.system.module = {
        dotfiles.kubernetes.enable = true;
        boot.initrd.availableKernelModules = ["xhci_pci" "usbhid"];
        disko = recursiveUpdate lvmDisko {
          devices.disk.base = {
            device = "/dev/disk/by-id/ata-MTFDDAK256TBN-1AR1ZABHA_UGXVK01J7BDCER";
            content.partitions.root.end = "-51G";
          };
        };
      };
    };
    dingo = {
      install.host = "192.168.50.105";
      build.sshOptions = sshOptions;
      profiles.system.module = {
        dotfiles.kubernetes.enable = true;
        boot.initrd.availableKernelModules = ["xhci_pci" "usbhid"];
        disko = recursiveUpdate lvmDisko {
          devices.disk.base = {
            device = "/dev/disk/by-id/ata-LITEON_IT_LCS-256L9S_SD0E97900L2TH61100DL";
            content.partitions.root.end = "-51G";
          };
        };
      };
    };
    octopus = {
      install.host = "192.168.50.53";
      target.sshOptions = sshOptions;
      profiles.system.module = {
        dotfiles.kubernetes.enable = true;
        boot.initrd.availableKernelModules = ["ehci_pci" "megaraid_sas" "usbhid" "sr_mod"];
        boot.kernelModules = ["kvm-intel"];
        disko = recursiveUpdate lvmDisko {
          devices.disk.base = {
            device = "/dev/disk/by-id/scsi-36b82a720cf60ce002a80577e12e4a1a7";
            content.partitions.root.end = "-1T";
          };
        };
      };
    };
    # TODO fix login screen where I can't sign in (enter or submit doesn't work lol)
    # TODO moonlight-qt for to use axolotl as gaming server
    # NOTE https://moonlight-stream.org/
    # NOTE add libplacebo and vulkan-headers for HDR support
    systeamadeck = {
      install.host = "192.168.50.176";
      build.host = root;
      build.sshOptions = sshOptions;
      profiles.system.sshProtocol = "ssh";
      profiles.system.module = {pkgs, ...}: {
        imports = [inputs.jovian.nixosModules.jovian];
        boot.initrd.availableKernelModules = ["nvme" "xhci_pci" "usbhid" "sdhci_pci"];
        boot.kernelModules = ["kvm-amd"];
        disko = recursiveUpdate disko {devices.disk.base.device = "/dev/disk/by-id/nvme-Phison_ESMP001TMN48C3-E21TS_23445M001T05978";};
        dotfiles.graphical.enable = true;
        dotfiles.graphical.sound.enable = true;
        environment.systemPackages = with pkgs; [maliit-keyboard maliit-framework];
        home-manager.sharedModules = toList ({
          config,
          lib,
          ...
        }: {
          dotfiles.email = true;
          home.packages = with pkgs; [heroic steam-tui];
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
          dotfiles.programs.steam.external = {
            enable = true;
            srm.userAccounts = ["supertriggy"];
            chiaki.enable = true;
            runescape = {
              rscplus.enable = true;
              saradomin.enable = true;
              runelite.enable = true;
              hdos.enable = true;
            };
            manual = {
              Kodi.shortcut.Exe = getExe pkgs.kodi;
              # TODO find a proper way to add browser to game mode (brave/chromium seems to fail)
              # brave.shortcut.Exe = getExe pkgs.brave;
              "Battle.Net".shortcut.Exe = pkgs.fetchurl {
                name = "Battle.net-Setup.exe";
                # https://www.battle.net/download/getInstallerForGame?os=win&gameProgram=BATTLENET_APP&version=Live
                url = "https://downloader.battle.net/download/getInstaller?os=win&installer=Battle.net-Setup.exe";
                hash = "sha256-FVeo035liq7s4MGpKp0yeVP1h/OkSnsQri55g6TQk+8=";
                executable = true;
              };
              # TODO declarative game controls
              # TODO how can I install interactively and set launcher afterwards?
              "The Legend of Pirates Online".shortcut.exe = getExe (inputs.erosanix.lib.${pkgs.system}.mkWindowsApp rec {
                pname = "The.Legend.of.Pirates.Online";
                version = "1.4.1";
                wine = pkgs.wineWowPackages.full;
                wineArch = "win64";
                src = pkgs.fetchurl {
                  url = "https://download.tlopo.com/TLOPO_${wineArch}_setup_${version}.exe";
                  hash = "sha256-8xx2HJi5sbJBpnRLMLVroNQ+ykNprA45xWPw+x6QRVA=";
                };
                dontUnpack = true;
                winAppInstall = ''
                  $WINE start /unix ${src} /S
                  wineserver -w
                '';
                winAppRun = "$WINE start /unix \"$WINEPREFIX/drive_c/Program Files/TLOPO/launcher.exe\"";
                installPhase = ''
                  runHook preInstall
                  ln -s $out/bin/.launcher $out/bin/TLOPO
                  runHook postInstall
                '';
                meta.mainProgram = "TLOPO";
              });
              # TODO why are these invalid when fetched?
              # NOTE upstream is obscured with browser request IDs giving 403, so I am hosting a mirror
              "Wizard 101".shortcut.Exe = pkgs.fetchurl {
                name = "InstallWizard101.exe";
                url = "https://drive.google.com/uc?id=1iVWSiEcGjwk_LKcp1937y4q3N3rt_JmQ";
                hash = "sha256-2ftofsBYx1PIeUvuBrieB3/AWJlvp36HtFd/xSk0jUs=";
                executable = true;
              };
              "Pirate 101".shortcut.Exe = pkgs.fetchurl {
                name = "InstallPirate101.exe";
                url = "https://drive.google.com/uc?id=1Nk_WThZYfW5xJII7G-JiL2rATpU3mA3k";
                hash = "sha256-+9gnfENkaN1wMs5vAG1CNKxToyNpT5XWWTRtdL+oZFw=";
                executable = true;
              };
            };
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
        });
        # TODO do I need to extract mura correction images?
        # NOTE https://github.com/Jovian-Experiments/Jovian-NixOS/issues/227
        # NOTE https://github.com/Jovian-Experiments/Jovian-NixOS/pull/229
        jovian.decky-loader = {
          enable = true;
          package = pkgs.decky-loader-prerelease;
          # TODO auto-generate these extraPackages
          extraPackages = [pkgs.pulseaudio];
          plugins = {
            # Working
            hltb.enable = true;
            volume-boost.enable = true;

            # Not working
            # TODO doesn't do anything...
            vibrant-deck.enable = true;
            # TODO self-host invidious so I don't compete for streaming bandwidth
            game-theme-music.enable = false;
            game-theme-music.settings.settings = {
              defaultMuted = false;
              volume = 0.52;
              invidiousInstance = "https://invidious.jing.rocks";
            };
            # junk-store.enable = true;

            # Untested
            css-loader.enable = true;
            animation-changer.enable = true;
          };
        };
        jovian.devices.steamdeck = {
          enable = true;
          autoUpdate = true;
          enableGyroDsuService = true;
        };
        jovian.steam = {
          enable = true;
          autoStart = true;
          desktopSession = "plasma";
          user = config.canivete.people.me;
        };
        networking.networkmanager.enable = true;
        programs.steam.extraCompatPackages = with pkgs; [proton-ge-bin steamtinkerlaunch steam-play-none];
        programs.steam.protontricks.enable = true;
        programs.gamemode.enable = true;
        programs.gamemode.enableRenice = true;
        services.displayManager.sddm.enable = false;

        # volume-boost
        systemd.services.decky-loader.environment.PULSE_SERVER = "tcp:127.0.0.1:4713";
        # TODO get cookie to work to minimze security surface
        # environment.etc."pulse/client.conf".text = "cookie-file = /home/${config.canivete.people.me}/.config/pulse/cookie";
        services.pipewire.extraConfig.pipewire-pulse."11-decky-volume-boost"."pulse.cmd" = toList {
          cmd = "load-module";
          args = "module-native-protocol-tcp auth-anonymous=true";
        };
      };
    };
  };
}
