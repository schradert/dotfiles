{config, inputs, lib, ...}: let
  inherit (config.canivete.meta) domain;
  inherit (builtins) elemAt genList length listToAttrs toString;
  inherit (lib) mergeAttrs mkForce nameValuePair optionalAttrs pipe recursiveUpdate;
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
in {
  perSystem.canivete.pre-commit.settings.excludes = ["nodes/nodes/.+\\.json"];
  # FIXME don't override
  # NOTE current thought is to install servers and deploy k8s before doing server/client updates
  canivete.deploy.nodes = {
    sirver.hostname = mkForce "192.168.50.185";
    octopus.hostname = mkForce "192.168.50.53";
    bonobo.hostname = mkForce "192.168.50.142";
    chinchilla.hostname = mkForce "192.168.50.85";
    dingo.hostname = mkForce "192.168.50.105";
  };
  dotfiles.nodes = {
    bootstrap = {
      platform.hetzner.server_type = "cpx11";
      opentofu.locals.bootstrap_ip = "\${ hcloud_server.bootstrap.ipv4_address }";
      system = {config, ...}: {
        services.cloudflare-dyndns = {
          enable = true;
          domains = ["headscale.${domain}" "bootstrap.ssh.${domain}"];
          apiTokenFile = config.sops.secrets."cloudflare/pat".path;
        };
        sops.secrets."cloudflare/pat" = {};
        # TODO convert to general server
        # dotfiles.profiles.server.enable = true;

        # TODO get ZFS and nixos-facter working
        disko = diskoExt4 "/dev/sda" {
          devices.disk.base.content.partitions.root.content.mountOptions = ["defaults" "x-systemd.growfs"];
        };
        facter.reportPath = mkForce null;
        # disko = diskoZfs "/dev/sda" [] {};
        # networking.hostId = "b008583a";
      };
    };
    sirver = {
      platform.prem.install_host = "192.168.50.23";
      system = {
        boot.initrd.availableKernelModules = ["sr_mod"];
        canivete.kubernetes.root = true;
        disko = diskoZfs "/dev/disk/by-id/scsi-35000c50067faa64b" [
          "/dev/disk/by-id/scsi-35000c50067fb404b"
          "/dev/disk/by-id/scsi-35000c50067fc5df3"
          "/dev/disk/by-id/scsi-35000c50067fc640b"
          "/dev/disk/by-id/scsi-35000c50067fcc0d3"
          "/dev/disk/by-id/scsi-35000c50067fcc2fb"
          "/dev/disk/by-id/scsi-35000c50067fcd9af"
          "/dev/disk/by-id/scsi-35000c50067fe560f"
        ] {};
        dotfiles.profiles.server.enable = true;
        dotfiles.tailscale.interface = "br0";
        networking.hostId = "799f2113";
        # Mini switch on spare LAN to connect another system (dingo)
        networking.bridges.br0.interfaces = ["eno3" "eno4"];
        networking.interfaces.br0.useDHCP = true;
      };
    };
    octopus = {
      platform.prem.install_host = "192.168.50.53";
      system = {
        boot.initrd.availableKernelModules = ["sr_mod"];
        disko = diskoZfs "/dev/disk/by-id/scsi-36b82a720cf60ce002fd94d2e2991b17e" [
          "/dev/disk/by-id/scsi-36b82a720cf60ce002fd94d462aff700b"
          "/dev/disk/by-id/scsi-36b82a720cf60ce002fd94d552bdede19"
          "/dev/disk/by-id/scsi-36b82a720cf60ce002fd94d622ca764e8"
          "/dev/disk/by-id/scsi-36b82a720cf60ce002fd94d6f2d66f068"
          "/dev/disk/by-id/scsi-36b82a720cf60ce002fd94d7c2e2ed82e"
          "/dev/disk/by-id/scsi-36b82a720cf60ce002fd94d8a2f011f94"
          "/dev/disk/by-id/scsi-36b82a720cf60ce002fd94d962fc2bcad"
        ] {};
        dotfiles.profiles.server.enable = true;
        networking.hostId = "101915fa";
        services.k3s.role = "server";
      };
    };
    bonobo = {
      platform.prem.install_host = "192.168.50.142";
      system = {
        disko = diskoZfs "/dev/disk/by-id/ata-Micron_1100_SATA_256GB_165015496CBD" [] {};
        dotfiles.profiles.server.enable = true;
        networking.hostId = "b090b069";
      };
    };
    chinchilla = {
      platform.prem.install_host = "192.168.50.85";
      system = {
        disko = diskoZfs "/dev/disk/by-id/ata-MTFDDAK256TBN-1AR1ZABHA_UGXVK01J7BDCER" [] {};
        dotfiles.profiles.server.enable = true;
        networking.hostId = "c419c417";
      };
    };
    dingo = {
      platform.prem.install_host = "192.168.50.105";
      system = {
        disko = diskoZfs "/dev/disk/by-id/ata-LITEON_IT_LCS-256L9S_SD0E97900L2TH61100DL" [] {};
        dotfiles.profiles.server.enable = true;
        networking.hostId = "d1960666";
      };
    };
    # TODO deploy
    axolotl = {
      platform.prem.install_host = "192.168.50.250";
      system = {
        # TODO Deactivate auto sleep
        disko = diskoZfs "/dev/disk/by-id/nvme-SPCC_M.2_PCIE_SSD_30012119169" [] {};
        dotfiles.profiles.client.enable = true;
        dotfiles.profiles.client.workstation.enable = true;
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
      };
    };
    # TODO deploy
    echidna = {
      platform.prem.install_host = "192.168.50.xxx";
      system = {
        # TODO fix modules to beef up WSL
        imports = [inputs.nixos-wsl.nixosModules.default];
        facter.reportPath = mkForce null;
        wsl.enable = true;
        wsl.defaultUser = config.canivete.meta.people.me;
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
      };
    };
    # TODO deploy
    systeamadeck = {
      platform.prem.install_host = "192.168.50.155";
      system = {pkgs, ...}: {
        imports = [inputs.jovian.nixosModules.jovian];
        disko = diskoZfs "/dev/disk/by-id/nvme-Phison_ESMP001TMN48C3-E21TS_23445M001T05978" [] {};
        dotfiles.profiles.client.enable = true;
        dotfiles.profiles.client.gaming.enable = true;
        dotfiles.nixpkgs.config.allowUnfreePackages = [
          "steam-run"
          "steam-jupiter-original"
          "steam-jupiter-unwrapped"
          "steamcmd"
          "steamdeck-hw-theme"
          "steam-original"
        ];
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
          user = config.canivete.meta.people.me;
        };
        networking.hostId = "58ea3dec";
        networking.networkmanager.enable = true;
      };
    };
    falcon = {
      platform.prem.install_host = "192.168.50.215";
      system = {
        boot.initrd.availableKernelModules = ["sr_mod"];
        # Firmware bug in ACPI DSDT table for Super IO + UART
        # Prevents kernel from even touching 8250 UART ports
        # TODO did this actually work? (it did at first but then maybe not...)
        boot.kernelParams = ["8250.nr_uarts=0"];
        # TODO convert to ZFS
        disko = diskoExt4 "/dev/disk/by-id/nvme-PC801_NVMe_SK_hynix_1TB__SIABN06591CB93G1B" {
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
        dotfiles.profiles.client.enable = true;
        dotfiles.profiles.client.gaming.enable = true;
        dotfiles.profiles.client.workstation.enable = true;
        dotfiles.profiles.nvidia.enable = true;
        # TODO why doesn't Continue work with vscodium? it just never loads...
        dotfiles.nixpkgs.config.allowUnfreePackages = ["vscode"];
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
      };
    };
  };
}