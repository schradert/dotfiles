{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.disko.url = "github:nix-community/disko";
  inputs.disko.inputs.nixpkgs.follows = "nixpkgs";
  inputs.home-manager.url = "github:nix-community/home-manager";
  inputs.home-manager.inputs.nixpkgs.follows = "nixpkgs";
  inputs.nixos-facter-modules.url = "github:nix-community/nixos-facter-modules";
  outputs = inputs: {
    nixosConfigurations.falcon = inputs.nixpkgs.lib.nixosSystem {
      modules = [
        ({
          config,
          lib,
          pkgs,
          ...
        }: {
          imports = [
            inputs.disko.nixosModules.default
            inputs.home-manager.nixosModules.home-manager
            inputs.nixos-facter-modules.nixosModules.facter
          ];
          boot.initrd.availableKernelModules = ["usbhid" "sr_mod"];
          boot.loader.systemd-boot.enable = true;
          boot.loader.efi.canTouchEfiVariables = true;
          disko.devices.disk = {
            base = {
              device = "/dev/disk/by-id/nvme-PC801_NVMe_SK_hynix_1TB__SIABN06591CB93G1B";
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
            data = {
              device = "/dev/disk/by-id/ata-TOSHIBA_MG08ADA400NY_X1Q0A2MPFYXG";
              type = "disk";
              content.type = "gpt";
              content.partitions.data = {
                size = "100%";
                content.type = "filesystem";
                content.format = "ext4";
                content.mountpoint = "/data";
              };
            };
          };
          environment.systemPackages = with pkgs; [ranger vim pavucontrol];
          facter.reportPath = ./facter.json;
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
          home-manager.backupFileExtension = "bak";
          home-manager.sharedModules = [
            ({
              config,
              lib,
              pkgs,
              ...
            }: let
              inherit (config) xdg;
            in {
              home.homeDirectory = "/home/${config.home.username}";
              home.sessionVariables = {
                XDG_CACHE_HOME = xdg.cacheHome;
                XDG_CONFIG_HOME = xdg.configHome;
                XDG_DATA_HOME = xdg.dataHome;
                XDG_STATE_HOME = xdg.stateHome;
                XDG_RUNTIME_DIR = "/run/user/1000";
              };
              home.packages = with pkgs; [brave beeper legcord spotify lazydocker k3d nix-inspect nix-fast-build heroic bitwarden];
              home.stateVersion = "25.05";
              nix.extraOptions = "experimental-features = nix-command flakes";
              programs.bash.enable = true;
              programs.bat.enable = true;
              programs.btop.enable = true;
              programs.dircolors.enable = true;
              programs.emacs.enable = true;
              programs.eza.enable = true;
              programs.fzf.enable = true;
              programs.direnv.enable = true;
              programs.gh.enable = true;
              programs.git.enable = true;
              programs.home-manager.enable = true;
              programs.jq.enable = true;
              programs.jqp.enable = true;
              programs.navi.enable = true;
              programs.obs-studio.enable = true;
              programs.rbw.enable = true;
              programs.ssh.enable = true;
              programs.starship.enable = true;
              programs.wezterm.enable = true;
              programs.yazi.enable = true;
              programs.zellij.enable = true;
              programs.zoxide.enable = true;
              programs.zsh.enable = true;
            })
          ];
          home-manager.users.tristan.home.username = "tristan";
          home-manager.useGlobalPkgs = true;
          i18n.defaultLocale = "en_US.UTF-8";
          networking.hostName = "falcon";
          nixpkgs.config.allowUnfreePredicate = pkg: lib.elem (lib.getName pkg) [
            "beeper"
            "nvidia-x11"
            "nvidia-settings"
            "nvidia-persistenced"
            "spotify"
            "steam"
            "steam-unwrapped"
          ];
          programs.gamemode.enable = true;
          programs.gamemode.enableRenice = true;
          programs.steam.enable = true;
          programs.steam.extraCompatPackages = with pkgs; [proton-ge-bin steamtinkerlaunch steam-play-none];
          programs.steam.protontricks.enable = true;
          security.rtkit.enable = true;
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
          services.pipewire = {
            enable = true;
            alsa.enable = true;
            alsa.support32Bit = true;
            pulse.enable = true;
            jack.enable = true;
          };
          services.desktopManager.plasma6.enable = true;
          services.displayManager.sddm.enable = true;
          services.openssh.enable = true;
          services.userborn.enable = true;
          services.xserver.enable = true;
          services.xserver.videoDrivers = ["nvidia"];
          system.stateVersion = "25.05";
          time.timeZone = "America/Los_Angeles";
          users.mutableUsers = true;
          users.users.root.openssh.authorizedKeys.keys = [(lib.fileContents ../../../.canivete/sops/tristan.pub)];
          users.users.tristan = {
            isNormalUser = true;
            home = "/home/tristan";
            description = "Tristan Schrader";
            extraGroups = ["wheel" "docker" "audio" "video"];
            openssh.authorizedKeys.keys = [(lib.fileContents ../../../.canivete/sops/tristan.pub)];
          };
          virtualisation.docker.enable = true;

          # Firmware bug in ACPI DSDT table for Super IO + UART
          # Prevents kernel from even touching 8250 UART ports
          # boot.kernelParams = ["8250.nr_uarts=0"];
          # Ignores motherboard serial port 00:03 in user space
          services.udev.extraRules = ''
            SUBSYSTEM=="tty", ATTRS{id}=="00:03", OPTIONS+="ignore_device"
          '';
        })
      ];
    };
  };
}
