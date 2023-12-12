{
  description = "System configuration";
  inputs = {
    home-manager.url = github:nix-community/home-manager/release-23.11;
    nixpkgs.url = github:nixos/nixpkgs/release-23.11;
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
  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "aarch64-darwin"];
      imports = [
        inputs.treefmt-nix.flakeModule
        inputs.nixos-flake.flakeModule
        ./src/home
        ./src/nixos
        ./src/nixos/kubernetes.nix
        ./src/darwin
        ./src/users
      ];
      flake = {
        overlays.default = inputs.nixpkgs.lib.composeManyExtensions [
          (import ./src/overlays/external.nix)
          (import ./src/overlays/internal.nix)
          inputs.emacs-overlay.overlay
          inputs.gke-gcloud-auth-plugin-flake.overlays.default
        ];
        nixosConfigurations.chilldom = inputs.nixpkgs.lib.nixosSystem {
          pkgs = import inputs.nixpkgs {
            system = "x86_64-linux";
            overlays = [inputs.self.overlays.default];
          };
          specialArgs = inputs.self.nixos-flake.lib.specialArgsFor.nixos;
          modules = [
            inputs.self.nixosModules.graphical
            ./src/systems/chilldom/hardware-configuration.nix
            ({lib, ...}: {
              networking.hostName = "chilldom";
              networking.wireless.enable = true;
              networking.wireless.networks.lanyard.psk = "bruhWHY123!";
              nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) ["discord" "android-studio" "spotify"];
            })
          ];
        };
        nixosConfigurations.sirver = inputs.nixpkgs.lib.nixosSystem {
          pkgs = import inputs.nixpkgs {
            system = "x86_64-linux";
            overlays = [inputs.self.overlays.default];
          };
          specialArgs = inputs.self.nixos-flake.lib.specialArgsFor.nixos;
          modules = [
            inputs.self.nixosModules.headless
            inputs.self.nixosModules.kubernetes
            ./src/systems/sirver/hardware-configuration.nix
            {
              networking.hostName = "sirver";
              home-manager.users.tristan = {
                imports = [./src/home/k9s];
              };
            }
          ];
        };
        darwinConfigurations.morgenmuffel = inputs.self.nixos-flake.lib.mkMacosSystem ({pkgs, ...}: {
          imports = [inputs.self.darwinModules.common];
          home-manager.users.${inputs.self.people.me}.home.packages = with pkgs; [
            google-cloud-sdk
            gke-gcloud-auth-plugin
            skhd
          ];
        });
      };
      perSystem = {
        self',
        config,
        pkgs,
        lib,
        system,
        ...
      }: {
        _module.args.pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = [inputs.self.overlays.default];
          config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) ["terraform"];
        };
        nixos-flake.primary-inputs = ["nixpkgs" "home-manager" "nix-darwin" "nixos-flake"];

        formatter = config.treefmt.build.wrapper;
        treefmt.config = {
          projectRootFile = "flake.nix";
          programs.alejandra.enable = true;
        };

        legacyPackages.homeConfigurations.tristanschrader = inputs.self.nixos-flake.lib.mkHomeConfiguration pkgs {
          imports = [
            inputs.self.homeModules.common
            inputs.self.homeModules.darwin-graphical
          ];
          hostname = "morgenmuffel";
          home.username = "tristanschrader";
          home.packages = with pkgs; [google-cloud-sdk gke-gcloud-auth-plugin deluge];
          nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) ["discord"];
        };

        packages.default = self'.packages.activate;
        packages.home = self'.packages.activate-home;
        packages.nux = pkgs.mk-nux-pkg ./src/nux;
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            kubectl
            kubernetes-helm
            nixos-rebuild
            sops
            ssh-to-age
            terraform
          ];
          shellHook = ''
            export PRJ_ROOT="$(git rev-parse --show-toplevel)"
            export KUBE_CONFIG_PATH="$PRJ_ROOT/run/secrets/config.yaml"
            export KUBECONFIG="$KUBE_CONFIG_PATH:$HOME/.kube/config"
            PATH_add bin
          '';
        };

        #  TODO (Tristan): convert these two packages into new system
        packages.sirver = inputs.terranix.lib.terranixConfiguration {
          inherit system pkgs;
          modules = [
            # ./src/infra/firefly.nix
            ({config, ...}: {
              provider.kubernetes = {
                config_path = "~/.kube/config";
                config_context = "k3d-local";
              };
              provider.helm = {inherit (config.provider) kubernetes;};
            })
            {
              terraform.required_providers = {
                github.source = "integrations/github";
                github.version = "5.42.0";
                flux.source = "fluxcd/flux";
                flux.version = "1.1.2";
              };
              resource.tls_private_key.flux = {
                algorithm = "ECDSA";
                ecdsa_curve = "P256";
              };
              resource.github_repository_deploy_key.flux = {
                key = "\${ tls_private_key.flux.public_key_openssh }";
                read_only = false;
                repository = "backbone";
                title = "Flux";
              };
              provider.flux = {
                kubernetes = {};
                git.url = "ssh://git@github.com/schradert/dotfiles";
                git.branch = "trunk";
                git.ssh = {
                  username = "git";
                  private_key = "\${ tls_private_key.flux.private_key_pem }";
                };
              };
              resource.flux_bootstrap_git.prod = {path = "src/nux/clusters/prod";};
            }
          ];
        };
        packages.local = inputs.terranix.lib.terranixConfiguration {
          inherit system pkgs;
          modules = [
            ./src/tix/sirver
            { locals.cluster.name = "sirver"; }
            # ./src/infra/firefly.nix
          ];
        };
      };
    };
}
