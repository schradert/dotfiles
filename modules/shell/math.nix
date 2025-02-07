{
  canivete.deploy.system.homeModules.math = {pkgs, ...}: {
    home.packages = with pkgs; [
      fend
    ];
  };
}
