{inputs, ...}: {
  dotfiles.nixos = {pkgs, ...}: {
    imports = [inputs.stylix.nixosModules.stylix];
    stylix.enable = true;
    stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/dracula.yaml";
  };
}
