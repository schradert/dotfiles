{
  flake.overlays.pug = final: _: {
    pug = final.callPackage ({
      lib,
      buildGoModule,
      fetchFromGitHub,
    }:
      buildGoModule rec {
        pname = "pug";
        version = lib.substring 0 7 src.rev;
        src = fetchFromGitHub {
          owner = "leg100";
          repo = "pug";
          rev = "37d0e02dd44092ad584977a0e54cc991551b3cb6";
          hash = "sha256-XQkQ9K3gB9wSgQ+Bt7Vl0xnA5mZCHiGLVx/gXuB9HNM=";
        };
        vendorHash = "sha256-jsZ7noyAhKvOVpcYwCY3DmRvAUOPUczeokat4u6n13A=";
        checkFlags = let
          skippedTests = [
            # Requires network access
            "TestTask_cancel"
            # TODO why does this have to be skipped? ERROR: fork/exec ./testdata/task: no such file or directory
            "TestTask_NewReader"
          ];
        in ["-skip=^${lib.concatStringsSep "$|^" skippedTests}$"];
        meta = {
          mainProgram = "pug";
          homepage = "https://github.com/leg100/pug";
          changelog = "${meta.homepage}/blob/${src.rev}/CHANGELOG.md";
          description = "Drive terraform at terminal velocity.";
          license = lib.licenses.mpl20;
        };
      }) {};
  };
  canivete.deploy.system.homeModules.pug = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (config.dotfiles.programs) pug;
    inherit (lib) mkEnableOption mkPackageOption mkOption mkIf types;
    yaml = pkgs.formats.yaml {};
  in {
    options.dotfiles.programs.pug = {
      enable = mkEnableOption "pug";
      package = mkPackageOption pkgs "pug" {};
      config = mkOption {
        inherit (yaml) type;
        default = {};
        description = "Structured contents of config.yaml";
      };
      finalPackage = mkOption {
        type = types.package;
        default = pug.package;
        readOnly = true;
      };
    };
    config = mkIf pug.enable {
      home.packages = [pug.package];
      dotfiles.programs.pug = {
        finalPackage = mkIf (pug.config != {}) (pkgs.wrapFlags pug.package "--add-flags \"--config ${yaml.generate "pug.config.yaml" pug.config}\"");
        config = {
          # TODO go through all of the settings I want to change
        };
      };
    };
  };
}
