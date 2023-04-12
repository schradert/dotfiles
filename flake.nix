{
  description = "System configuration";
  inputs = {
    darwin.url = github:lnl7/nix-darwin;
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    devshell.url = github:numtide/devshell;
    flake-utils.url = github:numtide/flake-utils;
    home-manager.url = github:nix-community/home-manager;
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixpkgs.url = github:nixos/nixpkgs;
    nix-doom-emacs.url = github:nix-community/nix-doom-emacs;
    nix-doom-emacs.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs =
    { self
    , darwin
    , devshell
    , flake-utils
    , home-manager
    , nixpkgs
    , nix-doom-emacs
    }: flake-utils.lib.eachDefaultSystem (system:
    let
      project = "dotfiles";
      pkgs = import nixpkgs { inherit system; overlays = (import ./overlays.nix) ++ [ devshell.overlays.default ]; };
      bin.write-script = name: text: (pkgs.writeScriptBin name text).overrideAttrs (old: {
        buildCommand = "${old.buildCommand}\n patchShebangs $out";
      });
      scripts.install = bin.write-script "install" ''
        #!/usr/bin/env bash
        if [[ -e /etc/nixos ]]; then
          sudo nixos-rebuild test --flake '.#'
        else
          nix build .#darwinConfigurations.morgenmuffel.system
          ./result/sw/bin/darwin-rebuild switch --flake .
        fi
      '';
    in
    {
      devShell = pkgs.devshell.mkShell {
        name = "${project}-shell";
        packages = with pkgs; [
          nixpkgs-fmt
        ];
      };
      packages.darwinConfigurations.morgenmuffel = darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = { inherit pkgs nix-doom-emacs home-manager; };
        modules = [ ./darwin ];
      };
      packages.nixosConfigurations.sirver = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit pkgs nix-doom-emacs home-manager; };
        modules = [ ./nixos/sirver ];
      };
      packages.nixosConfigurations.chilldom = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit pkgs nix-doom-emacs home-manager; };
        modules = [ ./nixos/chilldom ];
      };
      packages.install = scripts.install;
      packages.default = scripts.install;
    }
    );
}

