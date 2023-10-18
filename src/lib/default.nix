{ pkgs }:
{
  toYAML = obj:
    let
      input_f = builtins.toFile "obj.json" (builtins.toJSON obj);
      command = "remarshal -if json -i \"${input_f}\" -of yaml -o \"$out\"";
      output_f = pkgs.runCommand "to-yaml" { nativeBuildInputs = [ pkgs.remarshal ]; } command;
      values = [ (builtins.readFile output_f) ];
    in values;
  fromYAML = yaml:
    let
      input_f = if builtins.isPath yaml then yaml else builtins.toFile "obj.yaml" yaml;
      command = "remarshal -if yaml -i \"${input_f}\" -of json -o \"$out\"";
      output_f = pkgs.runCommand "from-yaml" { nativeBuildInputs = [ pkgs.remarshal ]; } command;
    in builtins.fromJSON (builtins.readFile output_f);
  subTemplateCmds = { template, cmds ? {} }:
    let
      contents_old = builtins.readFile template;
      cmds_sub_fmt = map (cmd: "\\${cmd}") (builtins.attrNames cmds);
      contents_new = builtins.replaceStrings cmds_sub_fmt (builtins.attrValues cmds) contents_old;
    in contents_new;
}
