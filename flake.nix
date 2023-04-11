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
    inputs@{ self
    , darwin
    , devshell
    , flake-utils
    , home-manager
    , nixpkgs
    , ...
    }: flake-utils.lib.eachDefaultSystem (system:
    let
      inherit (builtins) attrNames readDir;
      project = "dotfiles";

      pkgs = import nixpkgs { inherit system; overlays = [ devshell.overlays.default ]; };
      inherit (pkgs) writeScriptBin;
      inherit (pkgs.lib.attrsets) filterAttrs genAttrs;

      devices = attrNames (filterAttrs (_: v: v == "directory") (readDir ./devices));
      bin.write-script = name: text: (writeScriptBin name text).overrideAttrs (old: {
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
        modules = [
          ./darwin/configuration.nix
          home-manager.darwinModules.home-manager
#         ./home/home.nix
        ];
      };
      packages.nixosConfigurations = genAttrs devices (device: nixpkgs.lib.nixosSystem (rec {
        system = "x86_64-linux";
        specialArgs = inputs // { inherit system; };
        modules = [ (./. + "/devices/${device}/configuration.nix") ];
      }));
      packages.install = scripts.install;
      packages.default = scripts.install;
    }
    );
}

