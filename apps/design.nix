{
  dotfiles.darwin = {
    config,
    lib,
    ...
  }: {
    homebrew.casks = lib.mkIf config.dotfiles.profiles.workstation.enable [
      "freecad"
      "sweet-home3d"
    ];
  };
  dotfiles.home-manager = {
    canivete,
    config,
    lib,
    pkgs,
    ...
  }: {
    home.packages = with pkgs;
      lib.mkIf config.dotfiles.profiles.workstation.enable (lib.mkMerge [
        (canivete.mkIfElse config.dotfiles.graphical.hyprland.enable [freecad-wayland] [freecad])
        (lib.mkIf stdenv.hostPlatform.isLinux [
          sweethome3d.application
          sweethome3d.textures-editor
          sweethome3d.furniture-editor
        ])
        [textual-paint]
      ]);
  };
}
