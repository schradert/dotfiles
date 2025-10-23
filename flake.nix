{
  description = "System configuration";
  outputs = inputs: inputs.canivete.lib.mkFlake {inherit inputs;} [./infra ./modules] {};
  inputs = {
    ### REPOSITORY

    canivete.url = "github:schradert/canivete";
    canivete.inputs = {
      flake-parts.follows = "flake-parts";
      nixpkgs.follows = "nixpkgs";
      systems.follows = "systems";
    };

    # Essentials
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs-lib";
    # TODO why are these two inputs the only ones that show up double in flake.lock?!
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";

    # Deployment
    deploy-rs.url = "github:serokell/deploy-rs";
    deploy-rs.inputs = {
      flake-compat.follows = "flake-compat";
      nixpkgs.follows = "nixpkgs";
      utils.follows = "flake-utils";
    };
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-on-droid.url = "github:nix-community/nix-on-droid";
    nix-on-droid.inputs.home-manager.follows = "home-manager";
    nix-on-droid.inputs.nixpkgs.follows = "nixpkgs";
    # TODO submit feature upstream
    # nixos-anywhere.url = "github:nix-community/nixos-anywhere";
    nixos-anywhere.url = "github:schradert/nixos-anywhere";
    nixos-anywhere.inputs = {
      flake-parts.follows = "flake-parts";
      nixpkgs.follows = "nixpkgs";
      disko.follows = "disko";
      treefmt-nix.follows = "treefmt";
    };
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    srvos.url = "github:nix-community/srvos";
    srvos.inputs.nixpkgs.follows = "nixpkgs";
    nixos-facter-modules.url = "github:nix-community/nixos-facter-modules";
    nixos-generators.url = "github:nix-community/nixos-generators";
    nixos-generators.inputs.nixpkgs.follows = "nixpkgs";
    nixos-generators.inputs.nixlib.follows = "nixpkgs-lib";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nixos-wsl.url = "github:nix-community/NixOS-WSL";
    nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";
    nixos-wsl.inputs.flake-compat.follows = "flake-compat";
    mobile-nixos.url = "github:mobile-nixos/mobile-nixos";
    mobile-nixos.flake = false;

    # OpenTofu
    terranix.url = "github:terranix/terranix";
    terranix.inputs = {
      flake-parts.follows = "flake-parts";
      nixpkgs.follows = "nixpkgs";
      systems.follows = "systems";
    };
    # TODO should this be imported differently?
    opentofu-registry.url = "github:opentofu/registry";
    opentofu-registry.flake = false;

    # Containers + Kubernetes
    # TODO track https://github.com/arnarg/nixidy/pull/45
    # TODO track https://github.com/arnarg/nixidy/pull/46
    # nixidy.url = "github:arnarg/nixidy";
    nixidy.url = "github:schradert/nixidy/working";
    nixidy.inputs.nixpkgs.follows = "nixpkgs";
    nixidy.inputs.flake-utils.follows = "flake-utils";
    nixidy.inputs.nix-kube-generators.follows = "nix-kube-generators";
    nixhelm.url = "github:farcaller/nixhelm";
    nixhelm.inputs = {
      nixpkgs.follows = "nixpkgs";
      nix-kube-generators.follows = "nix-kube-generators";
      poetry2nix.follows = "poetry2nix";
      flake-utils.follows = "flake-utils";
    };
    nix-kube-generators.url = "github:farcaller/nix-kube-generators";
    nix2container.url = "github:nlewo/nix2container";
    nix2container.inputs.nixpkgs.follows = "nixpkgs";
    # NOTE Arion has no argument to prefer buildLayeredImage when streamLayeredImage doesn't work across systems
    # arion.url = "github:hercules-ci/arion";
    arion.url = "github:schradert/arion/build-layer-image";
    arion.inputs.flake-parts.follows = "flake-parts";
    arion.inputs.nixpkgs.follows = "nixpkgs";

    # Development tools
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    pre-commit.url = "github:cachix/git-hooks.nix";
    pre-commit.inputs = {
      nixpkgs.follows = "nixpkgs";
      gitignore.follows = "gitignore";
      flake-compat.follows = "flake-compat";
    };
    process-compose.url = "github:Platonic-Systems/process-compose-flake";
    services.url = "github:juspay/services-flake";

    # Misc.
    purescript-overlay.url = "github:thomashoneyman/purescript-overlay";
    purescript-overlay.inputs.flake-compat.follows = "flake-compat";
    purescript-overlay.inputs.nixpkgs.follows = "nixpkgs";
    dream2nix.url = "github:nix-community/dream2nix";
    dream2nix.inputs.nixpkgs.follows = "nixpkgs";
    dream2nix.inputs.purescript-overlay.follows = "purescript-overlay";
    climod.url = "github:nixosbrasil/climod";
    climod.flake = false;
    nix-alien.url = "github:thiagokokada/nix-alien";
    nix-alien.inputs.nixpkgs.follows = "nixpkgs";
    nix-alien.inputs.flake-compat.follows = "flake-compat";
    nix-alien.inputs.nix-index-database.follows = "nix-index-database";
    stylix.url = "github:nix-community/stylix";
    stylix.inputs = {
      nixpkgs.follows = "nixpkgs";
      flake-parts.follows = "flake-parts";
      nur.follows = "nur";
    };
    nix-index.url = "github:nix-community/nix-index";
    nix-index.inputs.nixpkgs.follows = "nixpkgs";
    nix-index.inputs.flake-compat.follows = "flake-compat";
    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    # GTK Application Framework
    ags.url = "github:aylur/ags";
    ags.inputs.nixpkgs.follows = "nixpkgs";

    ### PACKAGES

    # Collections
    nur.url = "github:nix-community/nur";
    nur.inputs.flake-parts.follows = "flake-parts";
    nur.inputs.nixpkgs.follows = "nixpkgs";
    mynur.url = "github:schradert/nur";
    mynur.inputs = {
      nixpkgs.follows = "nixpkgs";
      flake-parts.follows = "flake-parts";
      systems.follows = "systems";
      gradle2nix.follows = "gradle2nix";
      fenix.follows = "fenix";
    };
    gradle2nix.url = "github:tadfisher/gradle2nix";
    gradle2nix.inputs.flake-utils.follows = "flake-utils";
    gradle2nix.inputs.nixpkgs.follows = "nixpkgs";
    # TODO check out some of these modules, like for chiaki
    devusb.url = "github:devusb/nix-packages";
    devusb.inputs = {
      nixpkgs.follows = "nixpkgs";
      flake-parts.follows = "flake-parts";
      treefmt-nix.follows = "treefmt";
    };

    # Overrides
    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11";
    nixpkgs-lib.url = "github:nix-community/nixpkgs.lib";
    crane.url = "github:ipetkov/crane";
    flake-compat.url = "github:edolstra/flake-compat";
    flake-utils.url = "github:numtide/flake-utils";
    flake-utils.inputs.systems.follows = "systems";
    gitignore.url = "github:hercules-ci/gitignore.nix";
    gitignore.inputs.nixpkgs.follows = "nixpkgs";
    treefmt.url = "github:numtide/treefmt-nix";
    treefmt.inputs.nixpkgs.follows = "nixpkgs";
    nix-github-actions.url = "github:nix-community/nix-github-actions";
    systems-linux.url = "github:nix-systems/default-linux";
    fenix.url = "github:nix-community/fenix";
    fenix.inputs.nixpkgs.follows = "nixpkgs";

    # Network
    # NOTE https://github.com/awlsring/terraform-provider-headscale/issues/12
    headscale.url = "github:juanfont/headscale/v0.23.0";
    headscale.inputs.nixpkgs.follows = "nixpkgs";
    headscale.inputs.flake-utils.follows = "flake-utils";

    # Emacs
    nix-doom-emacs-unstraightened.url = "github:marienz/nix-doom-emacs-unstraightened";
    nix-doom-emacs-unstraightened.inputs = {
      nixpkgs.follows = "nixpkgs";
      emacs-overlay.follows = "emacs-overlay";
      systems.follows = "systems";
    };
    emacs-overlay.url = "github:nix-community/emacs-overlay";
    emacs-overlay.inputs.nixpkgs.follows = "nixpkgs";
    emacs-overlay.inputs.nixpkgs-stable.follows = "nixpkgs-stable";

    # Music
    spicetify-nix.url = "github:Gerg-L/spicetify-nix";
    spicetify-nix.inputs.nixpkgs.follows = "nixpkgs";
    spicetify-nix.inputs.systems.follows = "systems";

    # Gaming
    jovian.url = "github:Jovian-Experiments/Jovian-NixOS";
    jovian.inputs.nixpkgs.follows = "nixpkgs";
    jovian.inputs.nix-github-actions.follows = "nix-github-actions";
    nostatoo.url = "github:samueldr/nostatoo";
    nostatoo.flake = false;
    umu.url = "github:Open-Wine-Components/umu-launcher?dir=packaging/nix&submodules=1";
    umu.inputs.nixpkgs.follows = "nixpkgs";
    # mkWindowsApp
    erosanix.url = "github:emmanuelrosa/erosanix";
    erosanix.inputs.nixpkgs.follows = "nixpkgs";
    erosanix.inputs.flake-compat.follows = "flake-compat";

    # Terminal
    wezterm.url = "github:wez/wezterm/main?dir=nix";
    wezterm.inputs = {
      nixpkgs.follows = "nixpkgs";
      flake-utils.follows = "flake-utils";
      # NOTE WezTerm rust-overlay conflict (they did update it, but maybe it's a nixpkgs/nixos problem?)
      rust-overlay.follows = "rust-overlay";
    };
    zjstatus.url = "github:dj95/zjstatus";
    zjstatus.inputs = {
      nixpkgs.follows = "nixpkgs";
      crane.follows = "crane";
      flake-utils.follows = "flake-utils";
      rust-overlay.follows = "rust-overlay";
    };
    yazi.url = "github:sxyazi/yazi";
    yazi.inputs = {
      nixpkgs.follows = "nixpkgs";
      flake-utils.follows = "flake-utils";
      rust-overlay.follows = "rust-overlay";
    };
    superfile.url = "github:yorukot/superfile";
    superfile.inputs = {
      nixpkgs.follows = "nixpkgs";
      flake-compat.follows = "flake-compat";
      flake-utils.follows = "flake-utils";
    };
    naersk.url = "github:nix-community/naersk";
    naersk.inputs.nixpkgs.follows = "nixpkgs";
    naersk.inputs.fenix.follows = "fenix";
    television.url = "github:alexpasmantier/television";
    television.inputs = {
      nixpkgs.follows = "nixpkgs";
      flake-utils.follows = "flake-utils";
      naersk.follows = "naersk";
    };
    nci.url = "github:yusdacra/nix-cargo-integration";
    nci.inputs = {
      crane.follows = "crane";
      dream2nix.follows = "dream2nix";
      nixpkgs.follows = "nixpkgs";
      parts.follows = "flake-parts";
      rust-overlay.follows = "rust-overlay";
      treefmt.follows = "treefmt";
    };
    nix-inspect.url = "github:bluskript/nix-inspect";
    nix-inspect.inputs = {
      nixpkgs.follows = "nixpkgs";
      parts.follows = "flake-parts";
      nci.follows = "nci";
    };
    wiremix.url = "github:tsowell/wiremix";
    wiremix.inputs.nixpkgs.follows = "nixpkgs";
    wiremix.inputs.systems.follows = "systems-linux";

    # Browser
    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    zen-browser.inputs.nixpkgs.follows = "nixpkgs";
    zen-browser.inputs.home-manager.follows = "home-manager";

    # Languages
    haskell-nix.url = "github:input-output-hk/haskell.nix";
    haskell-nix.inputs = {
      nixpkgs.follows = "nixpkgs";
      nixpkgs-unstable.follows = "nixpkgs";
      flake-compat.follows = "flake-compat";
    };
    unison-src.url = "github:unisonweb/unison/release/0.5.36";
    unison-src.inputs.haskellNix.follows = "haskell-nix";
    unison-src.inputs.flake-utils.follows = "flake-utils";
    unison.url = "github:ceedubs/unison-nix";
    unison.inputs = {
      nixpkgs.follows = "nixpkgs";
      flake-utils.follows = "flake-utils";
      home-manager.follows = "home-manager";
      unison.follows = "unison-src";
    };

    # Window Manager
    matugen.url = "github:InioX/matugen";
    matugen.inputs.nixpkgs.follows = "nixpkgs";
    matugen.inputs.systems.follows = "systems";
    walker.url = "github:abenz1267/walker";
    walker.inputs.nixpkgs.follows = "nixpkgs";
    walker.inputs.systems.follows = "systems";
    gauntlet.url = "github:project-gauntlet/gauntlet";
    gauntlet.inputs = {
      crane.follows = "crane";
      flake-compat.follows = "flake-compat";
      flake-parts.follows = "flake-parts";
      nixpkgs.follows = "nixpkgs";
      systems.follows = "systems";
    };

    # Hyprland
    # NOTE hyprland changes way too frequently that it might make sense to permanently version pin
    hyprland.url = "github:hyprwm/Hyprland/v0.46.0";
    hyprland.inputs.nixpkgs.follows = "nixpkgs";
    hyprland.inputs.systems.follows = "systems-linux";
    hyprland.inputs.pre-commit-hooks.follows = "pre-commit";
    hyprland-plugins.url = "github:hyprwm/hyprland-plugins/v0.46.0";
    hyprland-plugins.inputs.hyprland.follows = "hyprland";
    hyprland-plugins.inputs.nixpkgs.follows = "nixpkgs";
    # TODO track https://github.com/pyt0xic/hyprfocus/pull/17
    # hyprfocus.url = "github:pyt0xic/hyprfocus";
    hyprfocus.url = "github:schradert/hyprfocus";
    hyprfocus.inputs.hyprland.follows = "hyprland";
    hyprpicker.url = "github:hyprwm/hyprpicker";
    hyprpicker.inputs = {
      nixpkgs.follows = "nixpkgs";
      hyprutils.follows = "hyprutils";
      systems.follows = "hyprland/systems";
      hyprwayland-scanner.follows = "hyprwayland-scanner";
    };
    grim-hyprland.url = "github:eriedaberrie/grim-hyprland";
    grim-hyprland.inputs.nixpkgs.follows = "nixpkgs";
    grim-hyprland.inputs.systems.follows = "hyprland/systems";
    poetry2nix.url = "github:nix-community/poetry2nix";
    poetry2nix.inputs = {
      flake-utils.follows = "flake-utils";
      nix-github-actions.follows = "nix-github-actions";
      nixpkgs.follows = "nixpkgs";
      systems.follows = "hyprland/systems";
      treefmt-nix.follows = "treefmt";
    };
    pyprland.url = "github:hyprland-community/pyprland";
    pyprland.inputs = {
      nixpkgs.follows = "nixpkgs";
      flake-compat.follows = "flake-compat";
      systems.follows = "systems";
      poetry2nix.follows = "poetry2nix";
    };
    hyprsome.url = "github:sopa0/hyprsome";
    hyprsome.inputs = {
      nixpkgs.follows = "nixpkgs";
      crane.follows = "crane";
      flake-utils.follows = "flake-utils";
    };
    hy3.url = "github:outfoxxed/hy3/hl0.46.0";
    hy3.inputs.hyprland.follows = "hyprland";
    # TODO track https://github.com/KZDKM/Hyprspace/pull/136
    # TODO track https://github.com/KZDKM/Hyprspace/pull/129
    # TODO track https://github.com/KZDKM/Hyprspace/issues/131
    hyprspace.url = "github:schradert/Hyprspace/v0.46.0";
    hyprspace.inputs.hyprland.follows = "hyprland";
    hyprspace.inputs.systems.follows = "hyprland/systems";
    # TODO revert to version pinning
    aquamarine.url = "github:hyprwm/aquamarine";
    aquamarine.inputs = {
      nixpkgs.follows = "hyprland/nixpkgs";
      hyprutils.follows = "hyprland/hyprutils";
      hyprwayland-scanner.follows = "hyprland/hyprwayland-scanner";
      systems.follows = "hyprland/systems";
    };
    hyprland.inputs.aquamarine.follows = "aquamarine";
    hyprcursor.url = "github:hyprwm/hyprcursor";
    hyprcursor.inputs = {
      nixpkgs.follows = "hyprland/nixpkgs";
      hyprlang.follows = "hyprland/hyprlang";
      systems.follows = "hyprland/systems";
    };
    hyprland.inputs.hyprcursor.follows = "hyprcursor";
    hyprland-protocols.url = "github:hyprwm/hyprland-protocols";
    hyprland-protocols.inputs.nixpkgs.follows = "hyprland/nixpkgs";
    hyprland-protocols.inputs.systems.follows = "hyprland/systems";
    hyprland.inputs.hyprland-protocols.follows = "hyprland-protocols";
    hyprlang.url = "github:hyprwm/hyprlang";
    hyprlang.inputs = {
      nixpkgs.follows = "hyprland/nixpkgs";
      hyprutils.follows = "hyprland/hyprutils";
      systems.follows = "hyprland/systems";
    };
    hyprland.inputs.hyprlang.follows = "hyprlang";
    hyprutils.url = "github:hyprwm/hyprutils";
    hyprutils.inputs.nixpkgs.follows = "hyprland/nixpkgs";
    hyprutils.inputs.systems.follows = "hyprland/systems";
    hyprland.inputs.hyprutils.follows = "hyprutils";
    hyprwayland-scanner.url = "github:hyprwm/hyprwayland-scanner";
    hyprwayland-scanner.inputs.nixpkgs.follows = "hyprland/nixpkgs";
    hyprwayland-scanner.inputs.systems.follows = "hyprland/systems";
    hyprland.inputs.hyprwayland-scanner.follows = "hyprwayland-scanner";
    xdph.url = "github:hyprwm/xdg-desktop-portal-hyprland";
    xdph.inputs = {
      nixpkgs.follows = "hyprland/nixpkgs";
      systems.follows = "hyprland/systems";
      hyprutils.follows = "hyprland/hyprutils";
      hyprlang.follows = "hyprland/hyprlang";
      hyprwayland-scanner.follows = "hyprland/hyprwayland-scanner";
      hyprland-protocols.follows = "hyprland/hyprland-protocols";
    };
    hyprland.inputs.xdph.follows = "xdph";
  };
}
