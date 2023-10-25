{ pkgs, ... }:
{
  home.shellAliases.spicetify = "spicetify-cli";
  home.packages = with pkgs; [ spicetify-cli ];
}
