{
  description = "System configuration";
  inputs = {
    devshell.url = github:numtide/devshell;
    devshell.inputs.nixpkgs.follows = "nixpkgs";
    devshell.inputs.flake-utils.follows = "flake-utils";
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
    , flake-utils
    , home-manager
    , nixpkgs
    , nix-doom-emacs
    , terranix
    }: flake-utils.lib.eachDefaultSystem (system:
    let
      project = "dotfiles";
      pkgs = import nixpkgs { inherit system; overlays = (import ./overlays.nix) ++ [ devshell.overlays.default ]; };
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
        modules = [
        ];
      };
      packages.nixosConfigurations.sirver = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = inputs // { inherit pkgs; };
        modules = [ ./nixos/sirver ];
      };
      packages.nixosConfigurations.chilldom = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit pkgs nix-doom-emacs home-manager; };
        modules = [ ./nixos/chilldom ];
      };
      packages.install = install;
      packages.default = install;
    }
    );
}

