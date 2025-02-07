{inputs, ...}: {
  flake.overlays.gauntlet = inputs.gauntlet.overlays.default;
  canivete.deploy.system.homeModules.gauntlet = {pkgs, ...}: {
    imports = [inputs.gauntlet.homeManagerModules.default];
    programs.gauntlet.enable = true;
    # TODO follow unstable changes for libffi-sys fixes
    programs.gauntlet.package = inputs.gauntlet.packages.${pkgs.system}.default;
    programs.gauntlet.service.enable = true;
  };
}
