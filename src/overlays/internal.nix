final: prev: {
  toYAMLFile = obj: let
    input_f = builtins.toFile "obj.json" (builtins.toJSON obj);
    command = "remarshal -if json -i \"${input_f}\" -of yaml -o \"$out\"";
    output_f = prev.runCommand "to-yaml" {nativeBuildInputs = [prev.remarshal];} command;
  in
    output_f;
  toYAML = obj: [(builtins.readFile (final.toYAMLFile obj))];
  fromYAML = yaml: let
    input_f =
      if prev.lib.strings.isStorePath yaml
      then yaml
      else builtins.toFile "obj.yaml" yaml;
    command = "remarshal -if yaml -i \"${input_f}\" -of json -o \"$out\"";
    output_f = prev.runCommand "from-yaml" {nativeBuildInputs = [prev.remarshal];} command;
  in
    prev.lib.trivial.importJSON output_f;
  subTemplateCmds = {
    template,
    cmds ? {},
  }: let
    contents_old = builtins.readFile template;
    cmds_sub_fmt = map (cmd: "\\${cmd}") (builtins.attrNames cmds);
    contents_new = builtins.replaceStrings cmds_sub_fmt (builtins.attrValues cmds) contents_old;
  in
    contents_new;
}
