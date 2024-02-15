{nix, ...}:
with nix; {
  flake.overlays.yaml = final: prev:
    with prev; {
      toYAML = pipe' [
        toJSON
        (toFile "obj.json")
        (file: "${remarshal}/bin/remarshal -if json -i ${file} -of yaml -o $out")
        (runCommand "to-yaml" {})
      ];
      fromYAML = pipe' [
        (yaml:
          if isPath yaml
          then yaml
          else toFile "yaml.yaml" yaml)
        (file: "${remarshal}/bin/remarshal -if yaml -i ${file} -of json -o $out")
        (runCommand "from-yaml" {})
        importJSON
      ];
    };
  flake.overlays.bash = final: prev: {
    execBash = command: ["${getExe final.bash}" "-c" command];
  };
}
