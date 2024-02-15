{
  description = "System configuration";
  inputs = {
    home-manager.url = github:nix-community/home-manager/release-23.11;
    nixpkgs.url = github:nixos/nixpkgs/release-23.11;
    nix-darwin.url = github:LnL7/nix-darwin;
    nix-on-droid.url = github:nix-community/nix-on-droid/release-23.05;

    systems-all.url = github:nix-systems/default;
    systems-default.url = github:nix-systems/x86_64-linux;
    systems-darwin.url = github:nix-systems/aarch64-darwin;

    nixos-flake.url = github:srid/nixos-flake;
    flake-parts.url = github:hercules-ci/flake-parts;
    pre-commit-hooks-nix.url = github:cachix/pre-commit-hooks.nix;

    # nix-doom-emacs marked as broken for now
    # TODO keep tabs on this project to see if it's evolving enough to try to use
    nix-doom-emacs.url = github:nix-community/nix-doom-emacs;
    emacs-overlay.url = github:nix-community/emacs-overlay;

    terranix.url = github:terranix/terranix;
    sops-nix.url = github:Mic92/sops-nix;
    gke-gcloud-auth-plugin-flake.url = github:christian-blades-cb/gke-gcloud-auth-plugin-nix;
    spicetify-nix.url = github:the-argus/spicetify-nix;
  };
  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      # TODO fix infinite recursion using `nix.mkIf`

      systems = import inputs.systems-all;
      imports = [./.];

      domain = "t0rdos.me";
      people = {
        me = "tristan";
        users.tristan = {
          name = "Tristan Schrader";
          accounts.github = "schradert";
          accounts.gitlab = "schrader.tristan";
          profiles.default.email = "t0rdos@pm.me";
        };
      };
      # nixos.sirver.module = {
      #   dotfiles.kubernetes.enable = true;
      #   # TODO allow creating another basic user
      #   # dotfiles.users.test.home.dotfiles.work.enable = true;
      #   boot.initrd.availableKernelModules = ["ehci_pci" "megaraid_sas" "usbhid"];
      # };
      # nixos.chilldom.module = {
      #   dotfiles.graphical.enable = true;
      #   boot.initrd.availableKernelModules = ["xhci_pci" "nvme" "rtsx_pci_sdmmc"];
      #   networking.wireless.enable = true;
      #   networking.wireless.networks.lanyard.psk = "bruhWHY123!";
      #   powerManagement.cpuFreqGovernor = "powersave";
      # };
      droid.boox = {};
      droid.mobile = {};
    };
}
