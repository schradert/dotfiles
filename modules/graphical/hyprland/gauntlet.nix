{inputs, ...}: {
  flake.overlays.gauntlet = inputs.gauntlet.overlays.default;
  # TODO submit override upstream
  flake.overlays.gauntlet-override = _: prev: {
    gauntlet = prev.gauntlet.override {
      npmDeps = prev.gauntlet.npmDeps.override {
        hash = "sha256-BOnKpFS0ofIZbmXcyEzHzHgvbgeg3QUXnC79BwKO6P8=";
      };
    };
  };
  canivete.deploy.system.homeModules.gauntlet = {
    config,
    lib,
    pkgs,
    ...
  }: {
    imports = [inputs.gauntlet.homeManagerModules.default];
    config = lib.mkIf config.dotfiles.workstation.enable {
      # TODO follow unstable changes for libffi-sys fixes
      programs.gauntlet.package = inputs.gauntlet.packages.${pkgs.system}.default;
      programs.gauntlet.service.enable = true;
      wayland.windowManager.hyprland.settings.bind = ["$mod+ALT, SPACE, exec, gauntlet open"];
    };
  };
}
