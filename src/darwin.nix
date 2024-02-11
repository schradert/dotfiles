{
  config,
  inputs,
  nix,
  withSystem,
  ...
}:
with nix; {
  options.darwin = mkOption {
    type = attrsOf (submodule {
      options.system = mkSystemOption {};
      options.module = mkOpenModuleOption {};
    });
    default = {};
    description = "Specific Nix-Darwin configurations";
  };
  options.flake = mkSubmoduleOptions {
    darwinModules_ = mkOpenModuleOption {
      description = mkDoc "Nix-Darwin modules";
    };
  };
  config.flake.darwinModules_.default = {
    users.users.${config.people.me} = {};
    system.stateVersion = 4;
  };
  config.flake.darwinConfigurations = mapAttrs (name: cfg:
    withSystem cfg.system ({
      pkgs,
      system,
      ...
    }:
      inputs.nix-darwin.lib.darwinSystem {
        inherit pkgs system;
        specialArgs = inputs.self.nixos-flake.lib.specialArgsFor.darwin;
        modules = toList (darwin: {
          imports = attrValues inputs.self.darwinModules_ ++ [cfg.module];
          nixpkgs.hostPlatform = system;
          dotfiles.hostname = mkDefault name;
          home-manager.users.${config.people.me}.dotfiles = darwin.config.dotfiles;
        });
      }))
  config.darwin;
}
