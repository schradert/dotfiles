{ pkgs, ... }:
let
  skin = builtins.fetchurl {
    url = "https://raw.githubusercontent.com/derailed/k9s/5a0a8f12e4cd2137badf8e2063c0ab3e3ff2f5cd/skins/dracula.yml";
    sha256 = "10is0kb0n6s0hd2lhyszrd6fln6clmhdbaw5faic5vlqg77hbjqs";
  };
in
{
  programs.k9s = {
    enable = true;
    skin = pkgs.lib.backbone.fromYAML skin;
  };
}
