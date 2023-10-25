{
  description = "System configuration";
  inputs = {
    home-manager.url = github:nix-community/home-manager/release-23.05;
    nixpkgs.url = github:nixos/nixpkgs/release-23.05;
    nix-darwin.url = github:LnL7/nix-darwin;

    nixos-flake.url = github:srid/nixos-flake;
    flake-parts.url = github:hercules-ci/flake-parts;
    treefmt-nix.url = github:numtide/treefmt-nix;

    nix-doom-emacs.url = github:nix-community/nix-doom-emacs;
    emacs-overlay.url = github:nix-community/emacs-overlay;

    sops-nix.url = github:Mic92/sops-nix;
    terranix.url = github:terranix/terranix;
    gke-gcloud-auth-plugin-flake.url = github:christian-blades-cb/gke-gcloud-auth-plugin-nix;
    spicetify-nix.url = github:the-argus/spicetify-nix;
  };
  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } {
    systems = [ "x86_64-linux" "aarch64-darwin" ];
    imports = [
      inputs.treefmt-nix.flakeModule
      inputs.nixos-flake.flakeModule
      ./src/home
      ./src/nixos
      ./src/darwin
      ./src/users
    ];
    flake = {
      # TODO (Tristan): get the climax-vps into both terraform and nix flake deployment
      nixosConfigurations.climax-vps = inputs.self.nixos-flake.lib.mkLinuxSystem {
        imports = [ inputs.self.nixosModules.default ];
      };
      nixosConfigurations.chilldom = inputs.self.nixos-flake.lib.mkLinuxSystem {
        imports = [ ./src/systems/chilldom ];
      };
      nixosConfigurations.sirver = inputs.self.nixos-flake.lib.mkLinuxSystem {
        imports = [ ./src/systems/sirver ];
      };
      darwinConfigurations.morgenmuffel = inputs.self.nixos-flake.lib.mkMacosSystem {
        imports = [ inputs.self.darwinModules.common ./src/systems/morgenmuffel ];
      };
    };
    perSystem = { self', inputs', config, pkgs, lib, system, ... }: {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = (import ./overlays.nix) ++ [
          inputs.emacs-overlay.overlay
          inputs.gke-gcloud-auth-plugin-flake.overlays.default
          (final: prev: { lib = prev.lib // { backbone = import ./src/lib { pkgs = final; }; }; })
        ];
      };
      nixos-flake.primary-inputs = [ "nixpkgs" "home-manager" "nix-darwin" "nixos-flake" ];

      formatter = config.treefmt.build.wrapper;
      treefmt.config = {
        projectRootFile = "flake.nix";
        programs.nixpkgs-fmt.enable = true;
      };

      legacyPackages.homeConfigurations.tristanschrader = inputs.self.nixos-flake.lib.mkHomeConfiguration pkgs {
        imports = [ inputs.self.homeModules.darwin-graphical ];
        home.username = "tristanschrader";
        home.packages = with pkgs; [ google-cloud-sdk gke-gcloud-auth-plugin ];
      };

      packages.default = self'.packages.activate;
      packages.home = self'.packages.activate-home;
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          kubectl
          kubernetes-helm
          nixpkgs-fmt
          sops
          ssh-to-age
          terraform
        ];
      };

      #  TODO (Tristan): convert these two packages into new system
      packages.local = inputs.terranix.lib.terranixConfiguration {
        inherit system pkgs;
        modules = [
          ./src/infra/firefly.nix
          ({ config, ... }: {
            config.provider.kubernetes = { config_path = "~/.kube/config"; config_context= "k3d-personal-local"; };
            config.provider.helm = { inherit (config.provider) kubernetes; };
          })
        ];
      };
      packages.install = pkgs.writeScriptBin "install" (pkgs.lib.backbone.subTemplateCmds {
        template = ./src/lib/install.sh;
        cmds.bash = "${pkgs.bash}/bin/bash";
      });

    };
  };
}
