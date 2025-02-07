{
  # TODO what is the quality difference between wallust with pgtk vs matugen
  canivete.deploy.nixos.homeModules.matugen = {
    config,
    lib,
    flake,
    ...
  }: let
    inherit (lib) mkAliasOptionModule mkOption mkIf types;
    inherit (config.dotfiles.programs) matugen;
  in {
    options.dotfiles.programs.matugen = mkOption {
      type = types.submodule {
        imports = [
          flake.inputs.matugen.nixosModules.default
          (mkAliasOptionModule ["enable"] ["programs" "matugen" "enable"])
        ];
        config.programs.matugen.config = {
          reload_apps = true;
          set_wallpaper = true;
          wallpaper_tool = "Swww";
          prefix = "@";
          swww_options = [
            "--transition-type"
            "fade"
            "--transition-step"
            "90"
            "--transition-duration"
            "2"
            "--transition-fps"
            "90"
          ];
          reload_apps_list.gtk_theme = true;
          custom_colors = {
            red = "#f38ba8";
            green = "#a6e3a1";
            yellow = "#f9e2af";
            blue = "#89b4fa";
            orange = "#fab387";
            purple = "#cba6f7";
          };
        };
      };
    };
    config =
      mkIf matugen.enable {
      };
  };
}
