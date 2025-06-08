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
    nixosConfigurations.falcon = inputs.nixpkgs.lib.nixosSystem {
      modules = [
        ({
          config,
          lib,
          pkgs,
          ...
        }: {
          imports = [inputs.home-manager.nixosModules.home-manager];
          boot.initrd.availableKernelModules = ["usbhid" "sr_mod"];
          boot.loader.systemd-boot.enable = true;
          boot.loader.efi.canTouchEfiVariables = true;
          environment.systemPackages = with pkgs; [ranger vim pavucontrol];
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
              home.packages = with pkgs; [brave beeper legcord spotify lazydocker k3d nix-inspect nix-fast-build bitwarden];
              home.stateVersion = "25.05";
              nix.extraOptions = "experimental-features = nix-command flakes";
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
              programs.wezterm.enable = true;
              programs.yazi.enable = true;
              programs.zellij.enable = true;
              programs.zoxide.enable = true;
            })
          ];
          home-manager.users.tristan.home.username = "tristan";
          home-manager.useGlobalPkgs = true;
          i18n.defaultLocale = "en_US.UTF-8";
          networking.hostName = "falcon";
          nixpkgs.config.allowUnfreePredicate = pkg:
            lib.elem (lib.getName pkg) [
              "beeper"
              "nvidia-x11"
              "nvidia-settings"
              "nvidia-persistenced"
              "spotify"
              "steam"
              "steam-unwrapped"
            ];
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
          services.openssh.enable = true;
          services.userborn.enable = true;
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
        })
        {
          # Desktop Manager
          services.desktopManager.plasma6.enable = true;
          services.displayManager.sddm.enable = true;
          services.displayManager.sddm.settings.General.DisplayServer = "wayland";
          services.xserver.enable = true;

          home-manager.sharedModules = [
            {
              # Seems like this file always conflicts in a Plasma session...
              # NOTE https://github.com/nix-community/home-manager/issues/6188#issuecomment-2749859294
              gtk.gtk2.force = true;
              # TODO why isn't the builtin Plasma 6 notification daemon not working?
              services.swaync.enable = true;
            }
          ];
        }
        ({pkgs, ...}: {
          # Gaming
          home-manager.sharedModules = [{home.packages = [pkgs.heroic];}];
          programs.gamemode.enable = true;
          programs.gamemode.enableRenice = true;
          programs.steam.enable = true;
          programs.steam.extraCompatPackages = with pkgs; [proton-ge-bin steamtinkerlaunch steam-play-none];
          programs.steam.protontricks.enable = true;
        })
        {
          # Facter
          imports = [inputs.nixos-facter-modules.nixosModules.facter];
          facter.reportPath = ./facter.json;
        }
        ({config, ...}: {
          # Nvidia
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
          services.xserver.videoDrivers = ["nvidia"];
        })
        {
          # TODO did this actually work? (it did at first but then maybe not...)
          # Firmware bug in ACPI DSDT table for Super IO + UART
          # Prevents kernel from even touching 8250 UART ports
          boot.kernelParams = ["8250.nr_uarts=0"];
        }
        ({pkgs, ...}: {
          # FHS compatibility
          environment.systemPackages = [pkgs.nix-alien];
          nixpkgs.overlays = [inputs.nix-alien.overlays.default];
          programs.nix-ld.enable = true;
          services.envfs.enable = true;
        })
        {
          # Disko
          imports = [inputs.disko.nixosModules.default];
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
        }
        ({pkgs, ...}: {
          # Styling
          imports = [inputs.stylix.nixosModules.stylix];
          stylix.enable = true;
          stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/dracula.yaml";
        })
        {
          # Shells
          home-manager.sharedModules = [
            ({config, lib, pkgs, ...}: {
              options.programs.elvish.interactiveExtra = lib.mkOption {
                type = lib.types.lines;
                default = "";
              };
              options.programs.xonsh.interactiveExtra = lib.mkOption {
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
                xdg.configFile."elvish/rc.elv".source = pkgs.writeText "rc.elv" config.programs.elvish.interactiveExtra;
                xdg.configFile."xonsh/rc.xsh".source = pkgs.writeText "rc.xsh" ''
                  if __xonsh__.env.get("XONSH_INTERACTIVE"):
                      ${config.programs.xonsh.interactiveExtra}
                '';
              };
            })
          ];
          # I don't want to recreate this module in home-manager
          programs.xonsh.enable = true;
        }
        {
          # For right prompt in Bash
          programs.bash.blesh.enable = true;
          home-manager.sharedModules = [
            ({config, lib, ...}: {
              # No builtin integration in home-manager for these shells
              programs.elvish.interactiveExtra = "eval (${lib.getExe config.programs.starship.package} init elvish)";
              programs.xonsh.interactiveExtra = "execx($(${lib.getExe config.programs.starship.package} init xonsh))";
            })
            ({lib, ...}: {
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
        }
      ];
    };
  };
}
