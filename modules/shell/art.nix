{
  canivete.deploy.system.homeModules.art = {pkgs, ...}: {
    home.packages = with pkgs; [
      artem
      ascii-image-converter
      dwt1-shell-color-scripts
      # TODO fix broken haskellPackages.tart
      # TODO build https://github.com/poetaman/arttime
      vhs
    ];
  };
}
