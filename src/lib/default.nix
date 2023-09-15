{ pkgs }:
{
  toYAML = obj:
    let
      input_f = builtins.toFile "obj.json" (builtins.toJSON obj);
      command = "remarshal -if json -i \"${input_f}\" -of yaml -o \"$out\"";
      output_f = pkgs.runCommand "to-yaml" { nativeBuildInputs = [ pkgs.remarshal ]; } command;
      values = [ (builtins.readFile output_f) ];
    in values;
  subTemplateCmds = { template, cmds ? {} }:
    let
      contents_old = builtins.readFile template;
      cmds_sub_fmt = map (cmd: "\\${cmd}") (builtins.attrNames cmds);
      contents_new = builtins.replaceStrings cmds_sub_fmt (builtins.attrValues cmds) contents_old;
    in contents_new;
}
