{
  dotfiles.darwin = {
    config,
    lib,
    ...
  }: {
    config = lib.mkIf config.dotfiles.graphical.enable {
      homebrew.casks = ["brave-browser" "zen-browser"];
    };
  };
  dotfiles.home-manager = {
    config,
    lib,
    perSystem,
    pkgs,
    ...
  }: {
    config = lib.mkIf config.dotfiles.graphical.enable (lib.mkMerge [
      {
        home.packages = with pkgs;
          lib.mkIf stdenv.hostPlatform.isLinux [
            brave
            perSystem.inputs'.zen-browser.packages.twilight
          ];
        wayland.windowManager.hyprland.settings."$browser" = "brave";
      }
      (lib.mkIf config.dotfiles.workstation.enable {
        home.packages = with pkgs;
          lib.mkMerge [
            [elink lagrange-tui ladybird]
            (lib.mkIf stdenv.hostPlatform.isLinux [luakit])
          ];
      })
    ]);
  };
}
