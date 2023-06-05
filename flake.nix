{
  description = "System configuration";
  inputs = {
    devshell.url = github:numtide/devshell;
    devshell.inputs.nixpkgs.follows = "nixpkgs";
    devshell.inputs.flake-utils.follows = "flake-utils";
    emacs-overlay.url = github:nix-community/emacs-overlay;
    flake-utils.url = github:numtide/flake-utils;
    home-manager.url = github:nix-community/home-manager;
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixpkgs.url = github:nixos/nixpkgs;
    nix-doom-emacs.url = github:nix-community/nix-doom-emacs;
    nix-doom-emacs.inputs.nixpkgs.follows = "nixpkgs";
    terranix.url = github:terranix/terranix;
    terranix.inputs.nixpkgs.follows = "nixpkgs";
    terranix.inputs.flake-utils.follows = "flake-utils";
  };
  outputs =
    inputs@{ self
    , devshell
    , emacs-overlay
    , flake-utils
    , home-manager
    , nixpkgs
    , nix-doom-emacs
    , terranix
    }: flake-utils.lib.eachDefaultSystem (system:
    let
      project = "dotfiles";
      pkgs = import nixpkgs {
        inherit system;
        overlays = (import ./overlays.nix) ++ [
          devshell.overlays.default
          emacs-overlay.overlay
        ];
        config.allowUnfreePredicate = pkg: builtins.elem pkg.pname [ "zoom" "discord" "slack" ];
      };
      shared = import ./lib/shared.nix { inherit pkgs; };
      inherit (shared.funcs) writeScriptBinFromTemplate;
      inherit (shared.cmds) bash;
      tf = rec {
        config = terranix.lib.terranixConfiguration { inherit system; modules = [ ./infra ]; };
        cli =
          let
            inherit (pkgs.lib) genAttrs;
            commands = [ "plan" "apply" "destroy" ];
            args = { inherit bash; terraform = "${pkgs.terraform}/bin/terraform"; };
            writeCommandScriptBinFromTemplate = command:
              writeScriptBinFromTemplate "tf.${command}" ./lib/tf-cmd.sh (args // { inherit command; });
          in
            genAttrs commands writeCommandScriptBinFromTemplate;
      };
      install = writeScriptBinFromTemplate "install" ./lib/install.sh { inherit bash; };
    in
    {
      devShell = pkgs.devshell.mkShell {
        name = "${project}-shell";
        packages = with pkgs; [
          kubectl
          kubernetes-helm
          terraform
        ];
      };
      packages.config = tf.config;
      packages.plan = tf.cli.plan;
      packages.apply = tf.cli.apply;
      packages.destroy = tf.cli.destroy;
      packages.homeConfigurations.tristanschrader = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          ./home
          {
            # We can explore https://github.com/Spotifyd/spotifyd as a spotify client on macOS?
            # The main one is only supported on x86_64-linux, but spotifyd works on all unix
            # The spicetify CLI possibly works on any system, so might be able to get it to work on macOS
            home.extraPackages = with pkgs; [ ranger skhd ];
          }
        ];
        extraSpecialArgs = { inherit nix-doom-emacs; };
      };
      packages.nixosConfigurations.sirver = nixpkgs.lib.nixosSystem rec {
        system = "x86_64-linux";
        specialArgs = { inherit pkgs; };
        modules = [
          ./nixos/sirver
          home-manager.nixosModules.home-manager
          {
            home-manager.extraSpecialArgs = specialArgs // { inherit nix-doom-emacs; };
            home-manager.users.tristan = import ./home;
            home-manager.useUserPackages = true;
            home-manager.useGlobalPkgs = true;
          }
        ];
      };
      packages.nixosConfigurations.chilldom = nixpkgs.lib.nixosSystem rec {
        system = "x86_64-linux";
        specialArgs = { inherit pkgs; };
        modules = [
          ./nixos/chilldom
          home-manager.nixosModules.home-manager
          {
            home-manager.extraSpecialArgs = specialArgs // { inherit nix-doom-emacs; };
            home-manager.users.tristan = import ./home;
            home-manager.useUserPackages = true;
            home-manager.useGlobalPkgs = true;
            home.extraPackages = with pkgs; [ android-studio ];
          }
        ];
      };
      packages.install = install;
      packages.default = install;
    }
    );
}

