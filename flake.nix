{
  description = "System configuration";
  inputs = {
    canivete.url = github:schradert/canivete;
    nixpkgs.follows = "canivete/nixpkgs";
    nixpkgs-stable.follows = "canivete/nixpkgs-stable";

    home-manager.url = github:nix-community/home-manager;
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-darwin.url = github:LnL7/nix-darwin;
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-on-droid.url = github:nix-community/nix-on-droid;
    nix-on-droid.inputs.nixpkgs.follows = "nixpkgs";

    systems-default.url = github:nix-systems/x86_64-linux;
    systems-darwin.url = github:nix-systems/aarch64-darwin;

    nixos-flake.url = github:srid/nixos-flake;

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
  };
  outputs = inputs:
    with inputs;
      canivete.lib.mkFlake {
        inherit inputs;
        everything = [./dev ./programs ./systems];
      } {
        imports = [nixos-flake.flakeModule ./work.nix];

        domain = "trdos.me";
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
        # nixos.sirver.ssh.hostname = "192.168.50.21";
        nixos.sirver.module = {
          # dotfiles.kubernetes.enable = true;
          boot.initrd.availableKernelModules = ["ehci_pci" "megaraid_sas" "usbhid"];
        };
        # nixos.chilldom.ssh.hostname = "192.168.50.250";
        nixos.chilldom.module = {
          dotfiles.graphical.enable = true;
          home-manager.users.tristan.programs.macchina.networkInterface = "enp0s31f6";
          boot.initrd.availableKernelModules = ["xhci_pci" "nvme" "rtsx_pci_sdmmc"];
          powerManagement.cpuFreqGovernor = "powersave";
        };
        droid.boox = {};
        droid.mobile = {};
      };
}
