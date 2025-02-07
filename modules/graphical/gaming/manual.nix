{inputs, ...}: {
  # TODO can I make this general to all steam types, not just jovian?
  flake.overlays.nostatoo = final: _: {
    nostatoo = (final.callPackage (inputs.nostatoo + "/nostatoo.nix") {}).overrideAttrs (_: {
      patches = [./nostatoo.patch];
      meta.mainProgram = "nostatoo";
    });
  };
  canivete.deploy.nixos.homeModules.nostatoo = {
    config,
    lib,
    pkgs,
    ...
  }: let
    json = pkgs.formats.json {};
    inherit (lib) concatStringsSep filterAttrs flip mkOption mkPackageOption literalExpression pipe mapAttrsToList toList types;
    inherit (types) attrsOf submodule str path pathInStore;
    inherit (config.dotfiles.programs.steam) external;
  in {
    options.dotfiles.programs.steam.external = {
      nostatoo = mkPackageOption pkgs "nostatoo" {};
      manual = mkOption {
        type = attrsOf (submodule ({name, ...}: {
          options.shortcut = mkOption {
            type = submodule {
              freeformType = json.type;
              options.appname = mkOption {type = str;};
              options.exe = mkOption {type = path;};
              options.StartDir = mkOption {
                type = str;
                default = "./";
              };
              config.appname = name;
            };
          };
          options.assets = mkOption {
            type = attrsOf pathInStore;
            default = {};
            example = literalExpression "{hero = ./chiaki/steam_hero.png;}";
            description = "Image assets to show alongside program in Steam UIs";
          };
        }));
        default = {};
        example = literalExpression "{chiaki-ng.exe = ./chiaki-launcher.sh;}";
        description = "Executables to add to steam library as non-steam games";
      };
    };
    config = {
      home.file."${builtins.dirOf external.directory}/Artwork".source = pkgs.buildEnv {
        name = "Artwork";
        paths = pipe external.manual [
          (filterAttrs (_: program: program.assets != {}))
          (mapAttrsToList (name: program:
            pkgs.runCommand "${name}-artwork" {} (pipe program.assets [
              (mapAttrsToList (type: path: "install -D --mode 644 ${path} $out/${type}/${name}"))
              (concatStringsSep "\n")
            ])))
        ];
      };
      dotfiles.programs.steam.external.consoles.Manual = {
        parsers.Manual.overrides.parserInputs.manualManifests = "\${romsdirglobal}\${/}Manual";
        # TODO connect local images to parserInputs
        programs = flip mapAttrsToList external.manual (
          name: game:
            pkgs.linkFarm "${name}.json" (toList {
              name = "${name}.json";
              path = json.generate "${name}.manifest.json" (toList {
                title = name;
                target = game.shortcut.exe;
                startIn = game.shortcut.StartDir;
                launchOptions = "";
                appendArgsToExecutable = true;
              });
            })
        );
      };
    };
  };
}
