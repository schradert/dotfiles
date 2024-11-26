{
  description = "System configuration";
  inputs = {
    canivete.url = github:schradert/canivete;

    # TODO move these dependency shifts upstream
    nixpkgs.url = github:nixos/nixpkgs/nixos-unstable;
    home-manager.url = github:nix-community/home-manager;
    home-manager.inputs.nixpkgs.follows = "canivete/nixpkgs";
    nix-darwin.url = github:LnL7/nix-darwin;
    nix-darwin.inputs.nixpkgs.follows = "canivete/nixpkgs";
    canivete.inputs.nixpkgs.follows = "nixpkgs";
    canivete.inputs.home-manager.follows = "home-manager";
    canivete.inputs.nix-darwin.follows = "nix-darwin";

    # TODO keep tabs on this project to see if it's evolving enough to try to use
    # NOTE nix-doom-emacs marked as broken for now so we use overlay
    # NOTE nix-doom-emacs-unstraightened might work better, but currently doesn't support org-roam
    nix-doom-emacs.url = github:nix-community/nix-doom-emacs;
    nix-doom-emacs.inputs.nixpkgs.follows = "canivete/nixpkgs";
    # nix-doom-emacs-unstraightened.url = github:marienz/nix-doom-emacs-unstraightened;
    # nix-doom-emacs-unstraightened.inputs.nixpkgs.follows = "canivete/nixpkgs";
    emacs-overlay.url = github:nix-community/emacs-overlay;
    emacs-overlay.inputs.nixpkgs.follows = "canivete/nixpkgs";
    emacs-overlay.inputs.nixpkgs-stable.follows = "canivete/nixpkgs-stable";

    # Secret management in Nix deployments
    sops-nix.url = github:Mic92/sops-nix;
    sops-nix.inputs.nixpkgs.follows = "canivete/nixpkgs";
    sops-nix.inputs.nixpkgs-stable.follows = "canivete/nixpkgs-stable";

    # Authenticate with GKE clusters using kubectl
    gke-gcloud-auth-plugin-flake.url = github:christian-blades-cb/gke-gcloud-auth-plugin-nix;

    # Spotify ecosystem
    spicetify-nix.url = github:Gerg-L/spicetify-nix;
    spicetify-nix.inputs.nixpkgs.follows = "canivete/nixpkgs";

    # NixOS on steamdeck
    jovian.url = github:Jovian-Experiments/Jovian-NixOS;
    jovian.inputs.nixpkgs.follows = "canivete/nixpkgs";

    # Docker images
    nix2container.url = github:nlewo/nix2container;
    nix2container.inputs.nixpkgs.follows = "canivete/nixpkgs";

    # More useful modules
    devusb.url = github:devusb/nix-packages;
    devusb.inputs.nixpkgs.follows = "canivete/nixpkgs";
    devusb.inputs.flake-parts.follows = "canivete/flake-parts";

    # WezTerm nightly
    wezterm.url = github:wez/wezterm/main?dir=nix;
    wezterm.inputs.nixpkgs.follows = "canivete/nixpkgs";
    # NOTE WezTerm rust-overlay conflict (they did update it, but maybe it's a nixpkgs/nixos problem?)
    rust-overlay.url = github:oxalica/rust-overlay;
    rust-overlay.inputs.nixpkgs.follows = "canivete/nixpkgs";
    wezterm.inputs.rust-overlay.follows = "rust-overlay";

    # Steam library manager
    nostatoo.url = github:samueldr/nostatoo;
    nostatoo.flake = false;

    # Umu game launcher
    umu.url = github:Open-Wine-Components/umu-launcher?dir=packaging/nix&submodules=1;
    umu.inputs.nixpkgs.follows = "canivete/nixpkgs";

    # mkWindowsApp
    erosanix.url = github:emmanuelrosa/erosanix;
    erosanix.inputs.nixpkgs.follows = "canivete/nixpkgs";

    # Wayland launcher
    walker.url = github:abenz1267/walker;
    walker.inputs.nixpkgs.follows = "canivete/nixpkgs";

    # AGS GTK widget design
    astal.url = github:aylur/astal;
    astal.inputs.nixpkgs.follows = "canivete/nixpkgs";
    ags.url = github:aylur/ags;
    ags.inputs.nixpkgs.follows = "canivete/nixpkgs";

    # Hyprland
    hyprland.url = github:hyprwm/Hyprland;
    hyprland.inputs.nixpkgs.follows = "canivete/nixpkgs";
    hyprland-plugins.url = github:hyprwm/hyprland-plugins;
    hyprland-plugins.inputs.hyprland.follows = "hyprland";
    hyprland-plugins.inputs.nixpkgs.follows = "canivete/nixpkgs";
    hyprfocus.url = github:pyt0xic/hyprfocus;
    hyprfocus.inputs.hyprland.follows = "hyprland";
    hyprsplit.url = github:shezdy/hyprsplit;
    hyprsplit.inputs.hyprland.follows = "hyprland";
    # TODO track PR https://github.com/outfoxxed/hy3/pull/156 to revert to master
    hy3.url = github:outfoxxed/hy3/36340e627d1b9c844ce73443db042c953ffdd1bf;
    hy3.inputs.hyprland.follows = "hyprland";
    # TODO track PR https://github.com/KZDKM/Hyprspace/pull/111 to revert to master
    hyprspace.url = github:KZDKM/Hyprspace/2f239d0569f8c380338bbd5aef99e7e8c41b9a09;
    hyprspace.inputs.hyprland.follows = "hyprland";
    # TODO revert to version pinning
    aquamarine.url = github:hyprwm/aquamarine;
    aquamarine.inputs.nixpkgs.follows = "hyprland/nixpkgs";
    aquamarine.inputs.hyprutils.follows = "hyprland/hyprutils";
    aquamarine.inputs.hyprwayland-scanner.follows = "hyprland/hyprwayland-scanner";
    hyprland.inputs.aquamarine.follows = "aquamarine";
    hyprcursor.url = github:hyprwm/hyprcursor;
    hyprcursor.inputs.nixpkgs.follows = "hyprland/nixpkgs";
    hyprcursor.inputs.hyprlang.follows = "hyprland/hyprlang";
    hyprland.inputs.hyprcursor.follows = "hyprcursor";
    hyprland-protocols.url = github:hyprwm/hyprland-protocols;
    hyprland-protocols.inputs.nixpkgs.follows = "hyprland/nixpkgs";
    hyprland.inputs.hyprland-protocols.follows = "hyprland-protocols";
    hyprlang.url = github:hyprwm/hyprlang;
    hyprlang.inputs.nixpkgs.follows = "hyprland/nixpkgs";
    hyprlang.inputs.hyprutils.follows = "hyprland/hyprutils";
    hyprland.inputs.hyprlang.follows = "hyprlang";
    hyprutils.url = github:hyprwm/hyprutils;
    hyprutils.inputs.nixpkgs.follows = "hyprland/nixpkgs";
    hyprland.inputs.hyprutils.follows = "hyprutils";
    hyprwayland-scanner.url = github:hyprwm/hyprwayland-scanner;
    hyprwayland-scanner.inputs.nixpkgs.follows = "hyprland/nixpkgs";
    hyprland.inputs.hyprwayland-scanner.follows = "hyprwayland-scanner";
    xdph.url = github:hyprwm/xdg-desktop-portal-hyprland;
    xdph.inputs.nixpkgs.follows = "hyprland/nixpkgs";
    xdph.inputs.hyprutils.follows = "hyprland/hyprutils";
    xdph.inputs.hyprlang.follows = "hyprland/hyprlang";
    xdph.inputs.hyprwayland-scanner.follows = "hyprland/hyprwayland-scanner";
    xdph.inputs.hyprland-protocols.follows = "hyprland/hyprland-protocols";
    hyprland.inputs.xdph.follows = "xdph";

    # TODO fix wiimmfi login
    # TODO FHS compatibility with envfs and nix-ld
    # NOTE https://github.com/nix-community/nix-ld
    # NOTE https://github.com/Mic92/envfs
    # NOTE Mic92's example: https://github.com/Mic92/dotfiles/blob/main/machines/modules/fhs-compat.nix
  };
  outputs = inputs:
    inputs.canivete.lib.mkFlake {
      inherit inputs;
      everything = [./modules ./builds];
    } ({
      config,
      nix,
      ...
    }:
      with nix; {
        dotfiles.domain = "trdos.me";
        canivete.root = "sirver";
        canivete.people = {
          me = "tristan";
          users.tristan = {
            name = "Tristan Schrader";
            accounts.github = "schradert";
            accounts.gitlab = "schrader.tristan";
            profiles.default.email = "t0rdos@pm.me";
            profiles.work.email = "tristan@climaxfoods.com";
          };
        };
        canivete.pkgs.config = {
          allowUnfreePredicate = pkg:
            elem (getName pkg) [
              "android-studio-stable"
              "aspell-dict-en-science"
              "discord"
              "displaylink"
              "raycast"
              "slack"
              "spotify"
              "beeper"
              "steam-run"
              "steam-jupiter-original"
              "steam-jupiter-unwrapped"
              "steam"
              "steamcmd"
              "steamdeck-hw-theme"
              "steam-original"
              # Sabnzbd only supports unrar currently, but unar is a better alternative to keep track of
              # NOTE https://github.com/sabnzbd/sabnzbd/issues/1120
              "unrar"
            ];
        };
        perSystem = {
          config,
          pkgs,
          ...
        }: {
          packages.default = pkgs.wrapFlags config.packages.opentofu "--add-flags \"deploy\"";
          canivete.pre-commit.languages.shell.enable = true;
          canivete.pre-commit.settings = {
            excludes = [".canivete/sops/.+"];
            # TODO extract these tool configurations into options
            hooks.lychee.settings.configPath = toString (pkgs.writers.writeTOML "lychee.toml" {
              exclude_path = ["^\./modules/programs/emacs/config\.org$"];
              exclude = [
                # These helm repositories don't have parent pages
                "https://seaweedfs.github.io/seaweedfs/helm"
                "https://seaweedfs.github.io/seaweedfs-csi-driver/helm"
                "https://charts.rook.io/release"
                "https://kubernetes-sigs.github.io/descheduler"
                "https://kubernetes-sigs.github.io/node-feature-discovery/charts"
                "https://k8tz.github.io/k8tz"
                "https://opensource.zalando.com/postgres-operator/charts/postgres-operator"
                "https://opensource.zalando.com/postgres-operator/charts/postgres-operator-ui"
                "https://gitlab.com/api/v4/projects/43892189/packages/helm/stable"
                # Cluster local addresses
                "svc.cluster.local"
                # URLs built with substitution
                "^.+\${.+}.+$"
                # DNS authority
                "^.+/dns-query$"
              ];
            });
            # Used in vim configuration
            hooks.typos.settings.configPath = toString (pkgs.writers.writeTOML "_typos.toml" {default.extend-words.enew = "enew";});
            # zsh not really supported by shfmt
            hooks.shfmt.excludes = ["programs/zsh/.p10k.zsh"];
          };
        };
        flake.dotfiles = mapAttrs (_: getAttr "dotfiles") config.allSystems;
      });
}
