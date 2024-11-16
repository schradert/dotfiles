{inputs, ...}: {
  # TODO can I make this general to all steam types, not just jovian?
  flake.overlays.nostatoo = final: _: {
    nostatoo = (final.callPackage (inputs.nostatoo + "/nostatoo.nix") {}).overrideAttrs (_: {
      patches = [./nostatoo.patch];
      meta.mainProgram = "nostatoo";
    });
  };
  canivete.deploy.nixos.homeModules.nostatoo = {config, lib, pkgs, ...}: let
    json = pkgs.formats.json {};
    inherit (lib) attrValues concatStringsSep flip getExe mkOption mkIf mkMerge mkPackageOption literalExpression pipe mapAttrsToList toList types;
    inherit (types) attrsOf submodule str path pathInStore;
    inherit (config.dotfiles.programs.steam) external;
    # NOTE non-steam games must start at this AppID (https://github.com/samueldr/nostatoo/issues/1)
    # appid_min = 2147488648;
    # gamesListJSON = json.generate "non-steam-games.json" (attrValues external.manual);
    # indexedGamesList = imap1 (i: recursiveUpdate {shortcut.appid = i + appid_min;}) (attrValues external.manual);
    nostatoo = getExe pkgs.nostatoo;
  in {
    options.dotfiles.programs.steam.external = {
      nostatoo = mkPackageOption pkgs "nostatoo" {};
      manual = mkOption {
        type = attrsOf (submodule ({name, ...}: {
          options.shortcut = mkOption {
            type = submodule {
              freeformType = json.type;
              options.appname = mkOption {type = str;};
              options.Exe = mkOption {type = path;};
              options.StartDir = mkOption {type = str; default = "./";};
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
        example = literalExpression "{chiaki-ng.Exe = ./chiaki-launcher.sh;}";
        description = "Executables to add to steam library as non-steam games";
      };
    };
    config = mkMerge [
      {
        dotfiles.programs.steam.external.consoles.Manual = {
          parsers.Manual.overrides.parserInputs.manualManifests = "\${romsdirglobal}\${/}Manual";
          # TODO local images?
          # TODO should I use this or nostatoo? nostatoo at least allows adding image derivations
          programs = flip mapAttrsToList config.dotfiles.programs.steam.external.manual (
            name: game: pkgs.linkFarm name (toList {
              inherit name;
              path = json.generate "${name}.manifest.json" {
                title = name;
                target = game.shortcut.Exe;
                startIn = game.shortcut.StartDir;
                launchOptions = "";
                appendArgsToExecutable = true;
              };
            })
          );
        };
      }
      (mkIf external.enable {
        home.activation.nostatoo = ''
          eval "$(
              ${getExe pkgs.jq} --null-input --raw-output --from-file ${./nostatoo.jq} --arg nostatoo ${nostatoo} \
              --argjson previous_dump "$(${nostatoo} dump-non-steam-games)" \
              --argjson incoming "$(cat ${json.generate "non-steam-games.json" (attrValues external.manual)})"
          )"
        '';
      })
    ];
  };
}
