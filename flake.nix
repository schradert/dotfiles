{
  description = "System configuration";
  outputs = inputs: inputs.canivete.lib.mkFlake {inherit inputs;} [./modules ./builds] ./default.nix;
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

    nixos-wsl.url = github:nix-community/NixOS-WSL;
    nixos-wsl.inputs.nixpkgs.follows = "canivete/nixpkgs";

    nur.url = github:nix-community/nur;
    nur.inputs.nixpkgs.follows = "canivete/nixpkgs";
    mynur.url = github:schradert/nur;
    mynur.inputs = {
      nixpkgs.follows = "canivete/nixpkgs";
      flake-parts.follows = "canivete/flake-parts";
      systems.follows = "canivete/systems";
    };

    # Terraform manifest generation
    terranix.url = github:terranix/terranix;
    terranix.inputs.nixpkgs.follows = "canivete/nixpkgs";

    # Kubernetes manifest generation
    # TODO follow updates and revert on merge
    # NOTE https://github.com/hall/kubenix/issues/52
    # kubenix.url = github:hall/kubenix;
    kubenix.url = github:schradert/kubenix/52-patch;
    kubenix.inputs.nixpkgs.follows = "nixpkgs";

    # OpenTofu dependency registry
    # TODO should this be imported differently?
    opentofu-registry.url = github:opentofu/registry;
    opentofu-registry.flake = false;

    dream2nix.url = github:nix-community/dream2nix;
    dream2nix.inputs.nixpkgs.follows = "canivete/nixpkgs";

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

    # Helix editor
    helix.url = github:usagi-flow/evil-helix;
    helix.inputs.nixpkgs.follows = "canivete/nixpkgs";
    helix.inputs.rust-overlay.follows = "rust-overlay";

    # Umu game launcher
    umu.url = github:Open-Wine-Components/umu-launcher?dir=packaging/nix&submodules=1;
    umu.inputs.nixpkgs.follows = "canivete/nixpkgs";

    # mkWindowsApp
    erosanix.url = github:emmanuelrosa/erosanix;
    erosanix.inputs.nixpkgs.follows = "canivete/nixpkgs";

    # Zellij bar
    zjstatus.url = github:dj95/zjstatus;
    zjstatus.inputs.nixpkgs.follows = "canivete/nixpkgs";
    zjstatus.inputs.rust-overlay.follows = "rust-overlay";

    # Wayland launcher
    walker.url = github:abenz1267/walker;
    walker.inputs.nixpkgs.follows = "canivete/nixpkgs";

    gauntlet.url = github:project-gauntlet/gauntlet;
    # NOTE see gauntlet.nix
    # gauntlet.inputs.nixpkgs.follows = "canivete/nixpkgs";

    # AGS GTK widget design
    astal.url = github:aylur/astal;
    astal.inputs.nixpkgs.follows = "canivete/nixpkgs";
    ags.url = github:aylur/ags;
    ags.inputs.nixpkgs.follows = "canivete/nixpkgs";

    # Theme switching
    matugen.url = github:InioX/matugen;
    matugen.inputs.nixpkgs.follows = "canivete/nixpkgs";

    yazi.url = github:sxyazi/yazi;
    yazi.inputs.nixpkgs.follows = "canivete/nixpkgs";
    yazi.inputs.rust-overlay.follows = "rust-overlay";
    superfile.url = github:yorukot/superfile;
    superfile.inputs.nixpkgs.follows = "canivete/nixpkgs";
    television.url = github:alexpasmantier/television;
    television.inputs.nixpkgs.follows = "canivete/nixpkgs";
    nix-inspect.url = github:bluskript/nix-inspect;
    nix-inspect.inputs.nixpkgs.follows = "canivete/nixpkgs";
    unison.url = github:ceedubs/unison-nix;
    unison.inputs.nixpkgs.follows = "canivete/nixpkgs";
    unison.inputs.home-manager.follows = "canivete/home-manager";
    zen-browser.url = github:0xc000022070/zen-browser-flake;
    zen-browser.inputs.nixpkgs.follows = "canivete/nixpkgs";

    deploy.url = github:serokell/deploy-rs;
    deploy.inputs.nixpkgs.follows = "canivete/nixpkgs";

    # Hyprland
    # NOTE hyprland changes way too frequently that it might make sense to permanently version pin
    hyprland.url = github:hyprwm/Hyprland/v0.46.0;
    hyprland.inputs.nixpkgs.follows = "canivete/nixpkgs";
    hyprland-plugins.url = github:hyprwm/hyprland-plugins/v0.46.0;
    hyprland-plugins.inputs.hyprland.follows = "hyprland";
    hyprland-plugins.inputs.nixpkgs.follows = "canivete/nixpkgs";
    # TODO track https://github.com/pyt0xic/hyprfocus/pull/17
    # hyprfocus.url = github:pyt0xic/hyprfocus;
    hyprfocus.url = github:schradert/hyprfocus;
    hyprfocus.inputs.hyprland.follows = "hyprland";
    hyprpicker.url = github:hyprwm/hyprpicker;
    hyprpicker.inputs.nixpkgs.follows = "canivete/nixpkgs";
    hyprpicker.inputs.hyprutils.follows = "hyprutils";
    hyprpicker.inputs.hyprwayland-scanner.follows = "hyprwayland-scanner";
    grim-hyprland.url = github:eriedaberrie/grim-hyprland;
    grim-hyprland.inputs.nixpkgs.follows = "canivete/nixpkgs";
    pyprland.url = github:hyprland-community/pyprland;
    pyprland.inputs.nixpkgs.follows = "canivete/nixpkgs";
    hyprsome.url = github:sopa0/hyprsome;
    hyprsome.inputs.nixpkgs.follows = "canivete/nixpkgs";
    hy3.url = github:outfoxxed/hy3/hl0.46.0;
    hy3.inputs.hyprland.follows = "hyprland";
    # TODO track https://github.com/KZDKM/Hyprspace/pull/136
    # TODO track https://github.com/KZDKM/Hyprspace/pull/129
    # TODO track https://github.com/KZDKM/Hyprspace/issues/131
    hyprspace.url = github:schradert/Hyprspace/v0.46.0;
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
}
