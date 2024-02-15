{inputs, ...}: let
  lib = inputs.nixpkgs.lib;
  flake-parts-lib = inputs.flake-parts.lib;

  # Convenience functions
  switch = function: arg1: arg2: function arg2 arg1;
  pipe' = switch lib.trivial.pipe;
  removeAttrs' = switch lib.attrsets.removeAttrs;
  flatMap = function: pipe' [(builtins.map function) lib.lists.flatten];
  # Borrowed from GitHub Gist from user udf@
  mkMergeTopLevel = names:
    pipe' [
      (lib.attrsets.foldAttrs (this: those: [this] ++ those) [])
      (builtins.mapAttrs (_: lib.mkMerge))
      (lib.attrsets.getAttrs names)
    ];

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
    lib.lists
    flake-parts-lib
    {
      inherit pipe' flatMap removeAttrs' switch;
      inherit mkEnabledOption mkOpenModuleOption mkSystemOption;
      fs = {inherit filter dirs files everything everythingBut;};
    }
  ];
in (with nix; {
  imports = fs.everything ./src ++ [./work.nix];
  options.flake = mkSubmoduleOptions {
    systemModules = mkOpenModuleOption {
      description = mkDoc "Modules common to system config tools (nixos, nix-darwin, nix-on-droid)";
    };
  };
  config = {
    _module.args.nix = nix;
    flake.systemModules.default = {
      _module.args.nix = nix;
      nix.extraOptions = ''
        experimental-features = nix-command flakes
      '';
    };
    flake.homeModules.args._module.args.nix = nix;
    perSystem = {system, ...}: {
      _module.args.nix = nix;
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = attrValues inputs.self.overlays;
        config.allowUnfreePredicate = pkg: elem (getName pkg) ["android-studio-stable" "discord" "raycast" "spotify" "terraform"];
      };
    };
  };
})
