{ pkgs }:
rec {
  cmds.bash = "${pkgs.bash}/bin/bash";
  funcs.templateWithArgs = template: baseArgs:
    let
      inherit (builtins) attrNames attrValues readFile replaceStrings;
      inherit (pkgs.lib.attrsets) mapAttrs' nameValuePair;
      args = mapAttrs' (name: value: nameValuePair ("@${name}@") value) baseArgs;
    in replaceStrings (attrNames args) (attrValues args) (readFile template);
  funcs.writeScriptBinFromTemplate = name: template: args: pkgs.writeScriptBin name (funcs.templateWithArgs template args);
}
