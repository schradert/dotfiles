{ pkgs, ... }:
{
  home.shellAliases.spicetify = "spicetify-cli";
  home.file.".config/spicetify/config-xpui.ini".source = ./config-xpui.ini;
  home.packages = with pkgs; [ spicetify-cli ];
}
