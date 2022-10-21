{
  description = "home-manager flake configuration";
  inputs = {
    devshell.url = "github:numtide/devshell";
    flake-utils.url = "github:numtide/flake-utils";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:nixos/nixpkgs";
  };
  outputs = inputs: inputs.flake-utils.lib.eachDefaultSystem(system:
    let
      macos = "aarch64-darwin";
      username = (if system == macos then "tristanschrader" else "schradert");
      homeDirectory =
        let prefix = (if system == macos then "/Users" else "/home");
        in "${prefix}/${username}";
      base = inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = inputs.nixpkgs.legacyPackages.${system};
        modules = [ { imports = [ ./home.nix ]; } ]; 
      };
    in {
      packages = rec {
        homeConfigurations = rec {
          tristanschrader = base;
          schradert = base;
          default = tristanschrader;
        };
        default = homeConfigurations.default.activationPackage;
      };
      devShell =
        let pkgs = import inputs.nixpkgs { inherit system; overlays = [ inputs.devshell.overlay ]; };
        in pkgs.devshell.mkShell {
          name = "home-manager-shell";
          commands = [ { package = "devshell.cli"; } ];
          packages = with pkgs; [ nixpkgs-fmt (python310.withPackages(ps: with ps; [ setuptools ])) ];
        };
    }
  );
}
