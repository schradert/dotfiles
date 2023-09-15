{
  description = "System configuration";
  inputs = {
    devshell.url = github:numtide/devshell;
    emacs-overlay.url = github:nix-community/emacs-overlay;
    flake-utils.url = github:numtide/flake-utils;
    home-manager.url = github:nix-community/home-manager;
    nixpkgs.url = github:nixos/nixpkgs/nixos-23.05;
    nix-doom-emacs.url = github:nix-community/nix-doom-emacs;
    terranix.url = github:terranix/terranix;
    gke-gcloud-auth-plugin-flake.url = github:christian-blades-cb/gke-gcloud-auth-plugin-nix;
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
    , gke-gcloud-auth-plugin-flake
    }: flake-utils.lib.eachDefaultSystem (system:
    let
      project = "dotfiles";
      pkgs = import nixpkgs {
        inherit system;
        overlays = (import ./overlays.nix) ++ [
          devshell.overlays.default
          emacs-overlay.overlay
          gke-gcloud-auth-plugin-flake.overlays.default
          (final: prev: { lib = prev.lib // { backbone = import ./src/lib { pkgs = final; }; }; })
        ];
        config.allowUnfreePredicate = pkg: builtins.elem pkg.pname [ "zoom" "discord" "slack" ];
      };
      x = pkgs.lib.backbone.subTemplateCmds {
        template = ./bin/x;
        cmds.bash = "${pkgs.bash}/bin/bash";
        cmds.terraform = "${pkgs.terraform}/bin/terraform";
      };
      install = pkgs.writeScriptBin "install" (pkgs.lib.backbone.subTemplateCmds {
        template = ./lib/install.sh;
        cmds.bash = "${pkgs.bash}/bin/bash";
      });
    in
    {
      devShell = pkgs.devshell.mkShell ({ ... }: {
        name = "${project}-shell";
        commands = [ { name = "x"; command = x; } ];
        packages = with pkgs; [
          kubectl
          kubernetes-helm
          terraform
        ];
      });
      };
      packages.homeConfigurations.tristanschrader = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          ./home
          {
            # We can explore https://github.com/Spotifyd/spotifyd as a spotify client on macOS?
            # The main one is only supported on x86_64-linux, but spotifyd works on all unix
            # The spicetify CLI possibly works on any system, so might be able to get it to work on macOS
            home.extraPackages = with pkgs; [
              element-desktop
              google-cloud-sdk
              gke-gcloud-auth-plugin
              k3d
              ranger
              skhd
            ];
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

