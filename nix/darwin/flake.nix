{
  description = "nix-darwin flake";
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-20.09-darwin";
    darwin = {
      url = "github:lnl7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = inputs: inputs.flake-utils.lib.eachDefaultSystem(system:
    let pkgs = import inputs.nixpkgs { inherit system; };
    in {
      darwinConfigurations.morgenmuffel = inputs.darwin.lib.darwinSystem {
        inherit system;
        modules = [ ./darwin-configuration.nix ];
      };
    }
  );
}
