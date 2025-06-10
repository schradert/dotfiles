{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixos-facter-modules.url = "github:nix-community/nixos-facter-modules";
    nix-alien.url = "github:thiagokokada/nix-alien";
    nix-alien.inputs.nixpkgs.follows = "nixpkgs";
    stylix.url = "github:nix-community/stylix";
    stylix.inputs.nixpkgs.follows = "nixpkgs";
    stylix.inputs.home-manager.follows = "home-manager";
  };
  outputs = inputs: {
    lib = let
      inherit (builtins) elemAt genList length listToAttrs toString;
      inherit (inputs.nixpkgs.lib) mergeAttrs nameValuePair nixosSystem optionalAttrs pipe recursiveUpdate;
    in {
      nixosSystem = name: modules: nixosSystem {
        inherit modules;
        specialArgs = {inherit name;};
      };
      # Disko does not actually merge NixOS modules (major bummer!)
      # I have to use recursiveUpdate within the same module for all settings to be detected and used
      # NOTE https://github.com/nix-community/disko/issues/678
      # NOTE https://github.com/NixOS/nixpkgs/pull/284551
      # FIXME sirver + octopus fail on first boot and emergency mode must be manually skipped
      diskoZfs = root: raid: recursiveUpdate {
        devices.disk = pipe raid [
          length
          (genList (index: nameValuePair "raid-${toString (index + 1)}" {
            type = "disk";
            device = elemAt raid index;
            content.type = "zfs";
            content.pool = "raid";
          }))
          listToAttrs
          (mergeAttrs {
            root = {
              device = root;
              type = "disk";
              content.type = "gpt";
              content.partitions = {
                ESP = {
                  type = "EF00";
                  size = "1G";
                  content = {
                    type = "filesystem";
                    format = "vfat";
                    mountpoint = "/boot";
                    mountOptions = ["umask=0077" "nofail"];
                  };
                };
                zfs = {
                  size = "100%";
                  content.type = "zfs";
                  content.pool = "root";
                };
              };
            };
          })
        ];
        devices.zpool = {
          root = {
            type = "zpool";
            rootFsOptions = {
              mountpoint = "none";
              compression = "lz4";
              acltype = "posixacl";
              xattr = "sa";
              "com.sun:auto-snapshot" = "true";
            };
            options.ashift = "12";
            datasets = {
              root.type = "zfs_fs";
              root.mountpoint = "/";
              home.type = "zfs_fs";
              home.mountpoint = "/home";
              tmp.type = "zfs_fs";
              tmp.mountpoint = "/tmp";
              tmp.options.sync = "disabled";
            };
          };
        } // (optionalAttrs (length raid > 0) {
          raid = {
            type = "zpool";
            rootFsOptions = {
              mountpoint = "none";
              compression = "lz4";
              acltype = "posixacl";
              xattr = "sa";
              "com.sun:auto-snapshot" = "true";
            };
            options.ashift = "12";
            mode.topology.type = "topology";
            mode.topology.vdev = [
              {
                mode = "raidz1";
                members = raid;
              }
            ];
            datasets.raid = {
              type = "zfs_fs";
              mountpoint = "/mnt/raid";
            };
          };
        });
      };
      diskoExt4 = base: recursiveUpdate {
        devices.disk.base = {
          device = base;
          type = "disk";
          content.type = "gpt";
          content.partitions = {
            boot = {
              priority = 1;
              type = "EF02";
              size = "1M";
            };
            ESP = {
              priority = 2;
              type = "EF00";
              size = "512M";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = ["umask=077"];
              };
            };
            root = {
              priority = 3;
              end = "-1G";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
                # TODO where does root partition need to be resizable
                # mountOptions = ["defaults" "x-systemd.growfs"];
              };
            };
            swap = {
              size = "100%";
              content.type = "swap";
              content.discardPolicy = "both";
              content.resumeDevice = true;
            };
          };
        };
      };
    };
    nixosModules = {
      systeamadeck = ./systeamadeck.nix;
      unfree = {
        config,
        lib,
        ...
      }: {
        options.node.nixpkgs.config.allowUnfreePackages = lib.mkOption {
          type = with lib.types; listOf str;
          default = [];
        };
        config.nixpkgs.config.allowUnfreePredicate = pkg: lib.elem (lib.getName pkg) config.node.nixpkgs.config.allowUnfreePackages;
      };
      plasma = {
        home-manager.sharedModules = [
          {
            # Seems like this file always conflicts in a Plasma session...
            # NOTE https://github.com/nix-community/home-manager/issues/6188#issuecomment-2749859294
            gtk.gtk2.force = true;
            # TODO why isn't the builtin Plasma 6 notification daemon not working?
            services.swaync.enable = true;
          }
        ];
        services.desktopManager.plasma6.enable = true;
        services.displayManager.sddm.enable = true;
        services.displayManager.sddm.settings.General.DisplayServer = "wayland";
        services.xserver.enable = true;
      };
      gaming = {pkgs, ...}: {
        node.nixpkgs.config.allowUnfreePackages = ["steam" "steam-unwrapped"];
        home-manager.sharedModules = [{home.packages = [pkgs.heroic];}];
        programs.gamemode.enable = true;
        programs.gamemode.enableRenice = true;
        programs.steam.enable = true;
        programs.steam.extraCompatPackages = with pkgs; [proton-ge-bin steamtinkerlaunch steam-play-none];
        programs.steam.protontricks.enable = true;
      };
      nvidia = {config, ...}: {
        hardware.nvidia = {
          modesetting.enable = true;
          open = true;
          package = config.boot.kernelPackages.nvidiaPackages.stable;
          powerManagement.enable = true;
          # TODO do I need this to fix minor flickering? how would I even implement it?
          # NOTE I don't have an iGPU but this fine-grained power management was suggested for graphical issues on suspend
          # powerManagement.finegrained = true;
          # prime.offload.enable = true;
          # prime.intelBusId = "";
          # prime.nvidiaBusId = "PCI:213:0:0";
        };
        nixpkgs.config.cudaSupport = true;
        node.nixpkgs.config.allowUnfreePackages = [
          "cuda_cccl"
          "cuda_cudart"
          "cuda_nvcc"
          "libcublas"
          "nvidia-x11"
          "nvidia-settings"
          "nvidia-persistenced"
        ];
        services.xserver.videoDrivers = ["nvidia"];
      };
      stylix = {pkgs, ...}: {
        imports = [inputs.stylix.nixosModules.stylix];
        stylix.enable = true;
        stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/dracula.yaml";
      };
      shells = {
        home-manager.sharedModules = [
          ({
            config,
            lib,
            pkgs,
            ...
          }: {
            options.node.programs.elvish.interactiveExtra = lib.mkOption {
              type = lib.types.lines;
              default = "";
            };
            options.node.programs.xonsh.interactiveExtra = lib.mkOption {
              type = lib.types.lines;
              default = "";
            };
            config = {
              home.packages = [pkgs.elvish];
              programs = {
                bash.enable = true;
                fish.enable = true;
                nushell.enable = true;
                zsh.enable = true;
              };
              xdg.configFile."elvish/rc.elv".source = pkgs.writeText "rc.elv" config.node.programs.elvish.interactiveExtra;
              xdg.configFile."xonsh/rc.xsh".source = pkgs.writeText "rc.xsh" ''
                if __xonsh__.env.get("XONSH_INTERACTIVE"):
                    ${config.node.programs.xonsh.interactiveExtra}
              '';
            };
          })
        ];
        # I don't want to recreate this module in home-manager for now...
        programs.xonsh.enable = true;
      };
      starship = {
        # For right prompt in Bash
        programs.bash.blesh.enable = true;
        home-manager.sharedModules = [
          ({
            config,
            lib,
            ...
          }: {
            # No builtin integration in home-manager for these shells
            node.programs.elvish.interactiveExtra = "eval (${lib.getExe config.programs.starship.package} init elvish)";
            node.programs.xonsh.interactiveExtra = "execx($(${lib.getExe config.programs.starship.package} init xonsh))";
            programs.starship.enable = true;
            programs.starship.settings = {
              format = lib.concatStrings [
                "$container"
                "$os "
                "$username@$hostname "

                "$directory"

                "$git_branch"
                "$git_commit"
                "$git_state"
                "$git_status"
                "$git_metrics"

                "$package"
                "$bun"
                "$dart"
                "$deno"
                "$go"
                "$gradle"
                "$haskell"
                "$helm"
                "$java"
                "$julia"
                "$kotlin"
                "$lua"
                "$nodejs"
                "$pulumi"
                "$python"
                "$rust"
                "$scala"
                "$terraform"
                "$typst"
                "$zig"

                "$docker_context"
                "$gcloud"
                "$kubernetes"

                "$line_break"

                "$shell"
                "$direnv"
                "$nix_shell"
                "$character"
              ];
              right_format = lib.concatStrings [
                "$status"
                "$cmd_duration"
                "$time"
                "$line_break"
              ];
              container.symbol = "󰆧 ";
              os.disabled = false;
              os.symbols = {
                NixOS = "";
                Windows = "";
                Raspbian = "󰐿";
                Macos = "󰀵";
                Linux = "󰌽";
                Alpine = "";
                Android = "";
                Debian = "󰣚";
              };
              username.format = "[$user]($style)";
              username.show_always = true;
              hostname.format = "[$ssh_symbol$hostname]($style)";
              hostname.ssh_only = false;
              hostname.ssh_symbol = "󱫋 ";
              directory = {
                fish_style_pwd_dir_length = 1;
                substitutions = {
                  "~/Documents" = "󰈙";
                  "~/Downloads" = "";
                  "~/Games" = "󰊗";
                  "~/Music" = "󰝚";
                  "~/Pictures" = "";
                  "~/Projects" = "󰲋";
                };
                truncation_symbol = ".../";
                truncate_to_repo = false;
              };
              direnv.symbol = " ";
              nix_shell.symbol = "󰜗 ";
              shell = {
                bash_indicator = " ";
                fish_indicator = "󰈺 ";
                zsh_indicator = "󰬇 ";
                powershell_indicator = " ";
                elvish_indicator = "🧝";
                xonsh_indicator = "🐚";
                cmd_indicator = " ";
                nu_indicator = " ";
                unknown_indicator = "󰞋 ";
                disabled = false;
              };
              git_metrics.disabled = false;
              bun.symbol = " ";
              dart.symbol = " ";
              deno.symbol = " ";
              golang.symbol = " ";
              gradle.symbol = " ";
              haskell.symbol = " ";
              helm.symbol = " ";
              java.symbol = "";
              julia.symbol = " ";
              kotlin.symbol = " ";
              lua.symbol = " ";
              nodejs.symbol = "󰎙 ";
              pulumi.symbol = " ";
              python.symbol = " ";
              rust.symbol = " ";
              scala.symbol = " ";
              terraform.symbol = " ";
              typst.symbol = " ";
              zig.symbol = " ";
              docker_context.symbol = " ";
              gcloud.symbol = "󱇶 ";
              kubernetes.disabled = false;
              kubernetes.symbol = " ";
              cmd_duration = {
                min_time = 0;
                show_milliseconds = true;
                show_notifications = true;
                min_time_to_notify = 15000;
              };
              status.disabled = false;
              time.disabled = false;
            };
          })
        ];
      };
      man = {pkgs, ...}: {
        # Man pages
        documentation.dev.enable = true;
        documentation.man.generateCaches = true;
        environment.systemPackages = [pkgs.man-pages pkgs.man-pages-posix];
      };
      facter = {name, ...}: {
        imports = [inputs.nixos-facter-modules.nixosModules.facter];
        # Basically everything has this...
        boot.initrd.availableKernelModules = ["usbhid"];
        facter.reportPath = ./. + "/${name}.json";
      };
      fhs = {pkgs, ...}: {
        environment.systemPackages = [pkgs.nix-alien];
        nixpkgs.overlays = [inputs.nix-alien.overlays.default];
        programs.nix-ld.enable = true;
        services.envfs.enable = true;
      };
      access = {lib, name, ...}: let
        key = lib.fileContents ../../.canivete/sops/tristan.pub;
      in {
        networking.hostName = name;
        security.sudo.extraRules = [
          {
            users = ["tristan"];
            commands = [
              {
                command = "ALL";
                options = ["NOPASSWD"];
              }
            ];
          }
        ];
        services.openssh.enable = true;
        services.userborn.enable = true;
        users.mutableUsers = true;
        users.users.root.openssh.authorizedKeys.keys = [key];
        users.users.tristan = {
          isNormalUser = true;
          home = "/home/tristan";
          description = "Tristan Schrader";
          extraGroups = ["wheel"];
          openssh.authorizedKeys.keys = [key];
        };
      };
      home = {
        imports = [inputs.home-manager.nixosModules.home-manager];
        home-manager.backupFileExtension = "bak";
        home-manager.sharedModules = [
          ({config, ...}: {
            home.homeDirectory = "/home/${config.home.username}";
            home.sessionVariables = let
              inherit (config) xdg;
            in {
              XDG_CACHE_HOME = xdg.cacheHome;
              XDG_CONFIG_HOME = xdg.configHome;
              XDG_DATA_HOME = xdg.dataHome;
              XDG_STATE_HOME = xdg.stateHome;
              XDG_RUNTIME_DIR = "/run/user/1000";
            };
            home.stateVersion = "25.05";
            programs = {
              bat.enable = true;
              btop.enable = true;
              dircolors.enable = true;
              eza.enable = true;
              fzf.enable = true;
              home-manager.enable = true;
              jq.enable = true;
              jqp.enable = true;
              ssh.enable = true;
              vim.enable = true;
              yazi.enable = true;
              zellij.enable = true;
              zoxide.enable = true;
            };
          })
        ];
        home-manager.users.tristan.home.username = "tristan";
        home-manager.useGlobalPkgs = true;
      };
      audio = {
        home-manager.sharedModules = [
          ({pkgs, ...}: {
            home.packages = with pkgs; [pavucontrol spotify];
          })
        ];
        node.nixpkgs.config.allowUnfreePackages = ["spotify"];
        security.rtkit.enable = true;
        services.pipewire = {
          enable = true;
          alsa.enable = true;
          alsa.support32Bit = true;
          pulse.enable = true;
          jack.enable = true;
        };
        users.users.tristan.extraGroups = ["audio"];
      };
      vm = {
        home-manager.sharedModules = [
          ({pkgs, ...}: {
            home.packages = [pkgs.lazydocker];
          })
        ];
        users.users.tristan.extraGroups = ["docker"];
        virtualisation.docker.enable = true;
      };
      video = {
        home-manager.sharedModules = [{programs.obs-studio.enable = true;}];
        users.users.tristan.extraGroups = ["video"];
      };
      code = {
        home-manager.sharedModules = [
          ({pkgs, ...}: {
            programs = {
              emacs.enable = true;
              direnv.enable = true;
              gh.enable = true;
              git.enable = true;
              navi.enable = true;
              wezterm.enable = true;
              vscode = {
                enable = true;
                package = pkgs.vscodium;
                profiles.default = {
                  enableExtensionUpdateCheck = false;
                  extensions = [pkgs.vscode-extensions.jnoortheen.nix-ide];
                  userSettings = {
                    "editor.guides.bracketPairs" = true;
                    "editor.insertSpaces" = true;
                    "editor.tabSize" = 4;
                    "editor.inlineSuggest.enabled" = true;
                  };
                };
              };
              zed-editor = {
                enable = true;
                extensions = ["dracula" "nix"];
                extraPackages = with pkgs; [nixd];
                installRemoteServer = true;
                userSettings.telemetry.metrics = false;
              };
            };
          })
        ];
      };
      nix = {
        home-manager.sharedModules = [
          ({pkgs, ...}: {
            home.packages = with pkgs; [nix-inspect nix-fast-build];
            nix.extraOptions = "experimental-features = nix-command flakes";
          })
        ];
      };
      nixos = {
        imports = [inputs.disko.nixosModules.default];
        boot.loader.systemd-boot.enable = true;
        boot.loader.efi.canTouchEfiVariables = true;
        i18n.defaultLocale = "en_US.UTF-8";
        system.stateVersion = "25.05";
        time.timeZone = "America/Los_Angeles";
      };
      common = {
        imports = with inputs.self.nixosModules; [unfree shells stylix starship man facter access home nix nixos];
      };
      server = {
        imports = with inputs.self.nixosModules; [common vm];
      };
      client = {
        imports = with inputs.self.nixosModules; [common plasma fhs audio video];
        home-manager.sharedModules = [
          ({pkgs, ...}: {
            home.packages = with pkgs; [brave beeper legcord k3d bitwarden];
            programs.rbw.enable = true;
          })
        ];
        node.nixpkgs.config.allowUnfreePackages = ["beeper"];
      };
      workstation = {
        imports = with inputs.self.nixosModules; [client code vm];
      };
    };
    nixosConfigurations = {
      sirver = inputs.self.lib.nixosSystem "sirver" [
        {
          imports = [inputs.self.nixosModules.server];
          boot.initrd.availableKernelModules = ["sr_mod"];
          disko = inputs.self.lib.diskoZfs "/dev/disk/by-id/scsi-35000c50067faa64b" [
            "/dev/disk/by-id/scsi-35000c50067fb404b"
            "/dev/disk/by-id/scsi-35000c50067fc5df3"
            "/dev/disk/by-id/scsi-35000c50067fc640b"
            "/dev/disk/by-id/scsi-35000c50067fcc0d3"
            "/dev/disk/by-id/scsi-35000c50067fcc2fb"
            "/dev/disk/by-id/scsi-35000c50067fcd9af"
            "/dev/disk/by-id/scsi-35000c50067fe560f"
          ] {};
          networking.hostId = "799f2113";
          # Mini switch on spare LAN to connect another system (dingo)
          networking.bridges.br0.interfaces = ["eno3" "eno4"];
          networking.interfaces.br0.useDHCP = true;
        }
      ];
      octopus = inputs.self.lib.nixosSystem "octopus" [
        {
          imports = [inputs.self.nixosModules.server];
          boot.initrd.availableKernelModules = ["sr_mod"];
          disko = inputs.self.lib.diskoZfs "/dev/disk/by-id/scsi-36b82a720cf60ce002fd94d2e2991b17e" [
            "/dev/disk/by-id/scsi-36b82a720cf60ce002fd94d462aff700b"
            "/dev/disk/by-id/scsi-36b82a720cf60ce002fd94d552bdede19"
            "/dev/disk/by-id/scsi-36b82a720cf60ce002fd94d622ca764e8"
            "/dev/disk/by-id/scsi-36b82a720cf60ce002fd94d6f2d66f068"
            "/dev/disk/by-id/scsi-36b82a720cf60ce002fd94d7c2e2ed82e"
            "/dev/disk/by-id/scsi-36b82a720cf60ce002fd94d8a2f011f94"
            "/dev/disk/by-id/scsi-36b82a720cf60ce002fd94d962fc2bcad"
          ] {};
          networking.hostId = "101915fa";
        }
      ];
      bonobo = inputs.self.lib.nixosSystem "bonobo" [
        {
          imports = [inputs.self.nixosModules.server];
          disko = inputs.self.lib.diskoZfs "/dev/disk/by-id/ata-Micron_1100_SATA_256GB_165015496CBD" [] {};
          networking.hostId = "b090b069";
        }
      ];
      chinchilla = inputs.self.lib.nixosSystem "chinchilla" [
        {
          imports = [inputs.self.nixosModules.server];
          disko = inputs.self.lib.diskoZfs "/dev/disk/by-id/ata-MTFDDAK256TBN-1AR1ZABHA_UGXVK01J7BDCER" [] {};
          networking.hostId = "c419c417";
        }
      ];
      dingo = inputs.self.lib.nixosSystem "dingo" [
        {
          imports = [inputs.self.nixosModules.server];
          disko = inputs.self.lib.diskoZfs "/dev/disk/by-id/ata-LITEON_IT_LCS-256L9S_SD0E97900L2TH61100DL" [] {};
          networking.hostId = "d1960666";
        }
      ];
      # TODO deploy
      axolotl = inputs.self.lib.nixosSystem "axolotl" [
        {
          # TODO Deactivate auto sleep
          imports = [inputs.self.nixosModules.workstation];
          disko = inputs.self.lib.diskoZfs "/dev/disk/by-id/nvme-SPCC_M.2_PCIE_SSD_30012119169" [] {};
          # home-manager.sharedModules = [{dotfiles.programs.macchina.networkInterface = "enp0s31f6";}];
          networking.hostId = "a6070877";
          services.logind.lidSwitch = "ignore";
          services.xserver.videoDrivers = ["radeon" "i915" "displaylink" "modesetting" "fbdev"];
          systemd.targets = {
            sleep.enable = false;
            suspend.enable = false;
            hibernate.enable = false;
            hybrid-sleep.enable = false;
          };
        }
      ];
      # TODO deploy
      echidna = inputs.self.lib.nixosSystem "echidna" [
        {
          # TODO fix modules to beef up WSL
          imports = [inputs.nixos-wsl.nixosModules.default];
          wsl.enable = true;
          wsl.defaultUser = "tristan";
          wsl.startMenuLaunchers = true;
          # TODO figure out hardwired internet setup (switch + ethernet to usb adapters)
          # TODO should I I use wsl-vpnkit?
          # TODO value of OpenGL driver from Windows?
          # TODO any settings I should configure for more resource usage or enable graphical applications?
          # wsl.usbip.enable = true;
          # wsl.usbip.autoAttach = [];
          # wsl.usbip.snippetIpAddress = "127.0.0.1";
          # wsl.useWindowsDriver = true;
          # wsl.wslConf = {};
        }
      ];
      # TODO deploy
      systeamadeck = inputs.self.lib.nixosSystem "systeamadeck" [
        inputs.jovian.nixosModules.jovian
        ({pkgs, ...}: {
          imports = with inputs.self.nixosModules; [client gaming];
          disko = inputs.self.lib.diskoZfs "/dev/disk/by-id/nvme-Phison_ESMP001TMN48C3-E21TS_23445M001T05978" [] {};
          environment.systemPackages = with pkgs; [maliit-keyboard maliit-framework];
          jovian.decky-loader = {
            enable = true;
            package = pkgs.decky-loader-prerelease;
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
            user = "tristan";
          };
          networking.hostId = "58ea3dec";
          networking.networkmanager.enable = true;
          node.nixpkgs.config.allowUnfreePackages = [
            "steam-run"
            "steam-jupiter-original"
            "steam-jupiter-unwrapped"
            "steamcmd"
            "steamdeck-hw-theme"
            "steam-original"
          ];
        })
      ];
      falcon = inputs.self.lib.nixosSystem "falcon" [
        {
          imports = with inputs.self.nixosModules; [workstation nvidia gaming];
          boot.initrd.availableKernelModules = ["sr_mod"];
          # Firmware bug in ACPI DSDT table for Super IO + UART
          # Prevents kernel from even touching 8250 UART ports
          # TODO did this actually work? (it did at first but then maybe not...)
          boot.kernelParams = ["8250.nr_uarts=0"];
          # TODO convert to ZFS
          disko = inputs.self.lib.diskoExt4 "/dev/disk/by-id/nvme-PC801_NVMe_SK_hynix_1TB__SIABN06591CB93G1B" {
            devices.disk.data = {
              type = "disk";
              device = "/dev/disk/by-id/ata-TOSHIBA_MG08ADA400NY_X1Q0A2MPFYXG";
              content.type = "gpt";
              content.partitions.data = {
                size = "100%";
                content.type = "filesystem";
                content.format = "ext4";
                content.mountpoint = "/data";
              };
            };
          };
        }
        {
          # AI coding
          # TODO why doesn't Continue work with vscodium? it just never loads...
          node.nixpkgs.config.allowUnfreePackages = ["vscode"];
          home-manager.sharedModules = [
            ({
              lib,
              pkgs,
              ...
            }: {
              programs.vscode.package = lib.mkForce pkgs.vscode;
              programs.vscode.profiles.default.extensions = [
                (pkgs.vscode-utils.buildVscodeMarketplaceExtension {
                  mktplcRef = {
                    name = "continue";
                    publisher = "Continue";
                    version = "1.1.40";
                    sha256 = "sha256-P4rhoj4Juag7cfB9Ca8eRmHRA10Rb4f7y5bNGgVZt+E=";
                    arch = "linux-x64";
                  };
                  nativeBuildInputs = [pkgs.autoPatchelfHook];
                  buildInputs = [pkgs.stdenv.cc.cc.lib];
                })
              ];
            })
          ];
          services.ollama.enable = true;
          services.ollama.loadModels = [
            "llama3.1:8b" # chat
            "qwen2.5-coder:1.5b-base" # autocomplete
            "nomic-embed-text:latest" # embeddings
          ];
        }
      ];
    };
  };
}
