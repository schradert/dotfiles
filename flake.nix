{
  description = "System configuration";
  inputs = {
    darwin.url = "github:lnl7/nix-darwin";
    devshell.url = "github:numtide/devshell";
    flake-utils.url = "github:numtide/flake-utils";
    home-manager.url = "github:nix-community/home-manager";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.11";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs =
    inputs@{ self
    , darwin
    , devshell
    , flake-utils
    , home-manager
    , nixpkgs
    }: flake-utils.lib.eachDefaultSystem (system:
    let
      inherit (builtins) map readFile;
      getAttrs = l: a: map (s: s.${a}) l;

      project = "dotfiles";
      pkgs = import nixpkgs { inherit system; overlays = [ devshell.overlay ]; };
      computers = [
        { hostname = "Nadjas-Air"; username = "tristanschrader"; }
        { hostname = "morgenmuffel"; username = "tristanschrader"; }
      ];
      hostnames = getAttrs computers "hostname";
      usernames = getAttrs computers "username";
      configs = {
        darwin = username: darwin.lib.darwinSystem {
          inherit system;
          modules = [
            ./darwin/configuration.nix
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.${username} = import ./home-manager/home.nix;
            }
          ];
        };
        home = home-manager.lib.homeManagerConfiguration { inherit pkgs; modules = [ ./home-manager/home.nix ]; };
        nixos = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./nixos/configuration.nix
            home-manager.nixosModules.home-manager
          ];
        };
      };
      scripts.install = (pkgs.writeScriptBin "install" (readFile ./_install.sh)).overrideAttrs (old: {
        buildCommand = "${old.buildCommand}\n patchShebangs $out";
      });
    in
    rec {
      devShell = pkgs.devshell.mkShell {
        name = "${project}-shell";
        commands = [{ package = "devshell.cli"; }];
        packages = with pkgs; [
          nixpkgs-fmt
        ];
      };

      darwinConfigurations = pkgs.lib.attrsets.genAttrs hostnames (u: configs.darwin u);
      nixosConfigurations = pkgs.lib.attrsets.genAttrs hostnames (_: configs.nixos);
      homeConfigurations = pkgs.lib.attrsets.genAttrs usernames (_: configs.home);

      packages = { inherit darwinConfigurations nixosConfigurations homeConfigurations; };
      packages.default = pkgs.symlinkJoin {
        name = "install";
        paths = [ scripts.install ];
        buildInputs = [ pkgs.makeWrapper ];
        postBuild = "wrapProgram $out/bin/install --prefix PATH : $out/bin";
      };
    }
    );
}

