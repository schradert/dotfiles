{inputs, ...}: let
  lib = inputs.nixpkgs.lib;
  flake-parts-lib = inputs.flake-parts.lib;

  # Convenience functions
  pipe' = functions: value: lib.trivial.pipe value functions;
  flatMap = function: pipe' [(builtins.map function) lib.lists.flatten];

  # Filesystem traversal
  filter = f: root:
    lib.trivial.pipe root [
      builtins.readDir
      (lib.attrsets.filterAttrs f)
      builtins.attrNames
      (builtins.map (file: root + "/${file}"))
    ];
  dirs = filter (_: type: type == "directory");
  files = filter (name: type: type == "regular" && builtins.match ".+\.nix$" name != null);
  everything = let
    filesAndDirs = root: [
      (files root)
      (builtins.map everything (dirs root))
    ];
  in
    pipe' [lib.lists.toList (flatMap filesAndDirs)];
  everythingBut = roots: exclude: builtins.filter (path: lib.lists.all (prefix: ! lib.path.hasPrefix prefix path) exclude) (everything roots);

  # Options
  mkEnabledOption = doc:
    lib.mkOption {
      type = lib.types.bool;
      default = true;
      example = false;
      description = lib.mdDoc "Whether to enable ${doc}";
    };
  mkSystemOption = args:
    lib.mkOption ({
        type = lib.types.enum (import inputs.systems-all);
        default = builtins.head (import inputs.systems-default);
        example = builtins.head (import inputs.systems-darwin);
        description = lib.mdDoc "System for the configuration";
      }
      // args);
  mkOpenModuleOption = args:
    lib.mkOption ({
        type = lib.types.lazyAttrsOf lib.types.unspecified;
        default = {};
      }
      // args);

  nix = lib.attrsets.mergeAttrsList [
    builtins
    lib
    lib.attrsets
    lib.strings
    lib.trivial
    lib.types
    flake-parts-lib
    {
      inherit pipe' flatMap;
      inherit mkEnabledOption mkOpenModuleOption mkSystemOption;
      fs = {inherit filter dirs files everything everythingBut;};
    }
  ];
in {
  imports = nix.fs.everything ./src;

  _module.args.nix = nix;

  perSystem = {
    config,
    pkgs,
    system,
    ...
  }: {
    _module.args.nix = nix;
    _module.args.pkgs = with nix;
      import inputs.nixpkgs {
        inherit system;
        overlays = attrValues inputs.self.overlays;
        config.allowUnfreePredicate = pkg: elem (getName pkg) ["terraform" "spotify" "android-studio-stable"];
      };
    devShells.default = pkgs.mkShell {
      inputsFrom = nix.attrValues (nix.removeAttrs config.devShells ["default"]);
    };
  };

  flake.nixosModules.args = {
    _module.args.nix = nix;
    home-manager.extraSpecialArgs.nix = nix;
  };
  flake.darwinModules_.args = {
    _module.args.nix = nix;
    home-manager.extraSpecialArgs.nix = nix;
  };
}
