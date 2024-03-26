{
  description = "System configuration";
  inputs = {
    nixpkgs.url = github:nixos/nixpkgs/nixos-unstable;
    nixpkgs-stable.url = github:nixos/nixpkgs/release-23.11;
    home-manager.url = github:nix-community/home-manager;
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-darwin.url = github:LnL7/nix-darwin;
    nix-on-droid.url = github:nix-community/nix-on-droid;
    nix-on-droid.inputs.nixpkgs.follows = "nixpkgs";

    systems-all.url = github:nix-systems/default;
    systems-default.url = github:nix-systems/x86_64-linux;
    systems-darwin.url = github:nix-systems/aarch64-darwin;

    nixos-flake.url = github:srid/nixos-flake;
    flake-parts.url = github:hercules-ci/flake-parts;
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
    pre-commit-hooks-nix.url = github:cachix/pre-commit-hooks.nix;
    pre-commit-hooks-nix.inputs.nixpkgs.follows = "nixpkgs";
    pre-commit-hooks-nix.inputs.nixpkgs-stable.follows = "nixpkgs-stable";

    # nix-doom-emacs marked as broken for now
    # TODO keep tabs on this project to see if it's evolving enough to try to use
    nix-doom-emacs.url = github:nix-community/nix-doom-emacs;
    nix-doom-emacs.inputs.nixpkgs.follows = "nixpkgs";
    emacs-overlay.url = github:nix-community/emacs-overlay;
    emacs-overlay.inputs.nixpkgs.follows = "nixpkgs";
    emacs-overlay.inputs.nixpkgs-stable.follows = "nixpkgs-stable";

    terranix.url = github:terranix/terranix;
    terranix.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = github:Mic92/sops-nix;
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.inputs.nixpkgs-stable.follows = "nixpkgs-stable";
    gke-gcloud-auth-plugin-flake.url = github:christian-blades-cb/gke-gcloud-auth-plugin-nix;
    spicetify-nix.url = github:the-argus/spicetify-nix;
    spicetify-nix.inputs.nixpkgs.follows = "nixpkgs";
    hyprland.url = github:hyprwm/Hyprland;
    hyprland.inputs.nixpkgs.follows = "nixpkgs";
    hyprland-plugins.url = github:hyprwm/hyprland-plugins;
    hyprland-plugins.inputs.hyprland.follows = "hyprland";
  };
  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      # TODO fix infinite recursion using `nix.mkIf`

      systems = import inputs.systems-all;
      imports = [./.];

      domain = "t0rdos.me";
      root = "sirver";
      people = {
        me = "tristan";
        users.tristan = {
          name = "Tristan Schrader";
          accounts.github = "schradert";
          accounts.gitlab = "schrader.tristan";
          profiles.default.email = "t0rdos@pm.me";
        };
      };
      nixos.sirver.module = {
        # dotfiles.kubernetes.enable = true;
        # TODO allow creating another basic user
        # dotfiles.users.test.home.dotfiles.work.enable = true;
        boot.initrd.availableKernelModules = ["ehci_pci" "megaraid_sas" "usbhid"];
      };
      nixos.chilldom.module = {
        dotfiles.graphical.enable = true;
        home-manager.users.tristan.programs.macchina.networkInterface = "enp0s31f6";
        boot.initrd.availableKernelModules = ["xhci_pci" "nvme" "rtsx_pci_sdmmc"];
        # networking.wireless.enable = false;
        # networking.wireless.networks.lanyard.psk = "bruhWHY123!";
        powerManagement.cpuFreqGovernor = "powersave";
      };
      droid.boox = {};
      droid.mobile = {};
    };
}
