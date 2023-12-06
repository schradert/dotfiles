final: prev: {
  fromJSONtoYAML = input_f: let
    command = "remarshal -if json -i \"${input_f}\" -of yaml -o \"$out\"";
  in prev.runCommand "from-json-to-yaml" {nativeBuildInputs = [prev.remarshal];} command;
  toYAMLFile = obj: let
    file = builtins.toFile "obj.json" (builtins.toJSON obj);
  in final.fromJSONtoYAML file;
  toYAML = obj: [(builtins.readFile (final.toYAMLFile obj))];
  fromYAML = yaml: let
    command = "remarshal -if yaml -i \"${builtins.toFile "yaml.yaml" yaml}\" -of json -o \"$out\"";
  in prev.lib.trivial.importJSON (prev.runCommand "from-yaml" {nativeBuildInputs = [prev.remarshal];} command);
  subTemplateCmds = {
    template,
    cmds ? {},
  }: let
    contents_old = builtins.readFile template;
    cmds_sub_fmt = map (cmd: "\\${cmd}") (builtins.attrNames cmds);
    contents_new = builtins.replaceStrings cmds_sub_fmt (builtins.attrValues cmds) contents_old;
  in
    contents_new;
  validate-nux-pkg = pkg: let
    errors = prev.lib.trivial.pipe pkg.config.assertions [
      (builtins.filter (assertion: !assertion.assertion))
      (map (builtins.getAttr "message"))
      (builtins.concatStringsSep "\n")
    ];
    failed = builtins.stringLength errors > 0;
  in prev.lib.trivial.throwIf failed errors pkg;
  map' = values: function: builtins.map function values;
  mk-nux-pkg = module: prev.lib.trivial.pipe module [
    (mod: prev.lib.evalModules { specialArgs.pkgs = final; modules = [mod]; })
    final.validate-nux-pkg
    (pkg: final.toYAMLFile { apiVersion = "v1"; kind = "List"; items = pkg.config.resources; })
  ];
}
