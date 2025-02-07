{
  canivete.deploy.system.homeModules.feh = {
    config,
    lib,
    ...
  }: let
    inherit (lib) mkEnableOption mkIf;
  in {
    options.dotfiles.programs.feh.enable = mkEnableOption "feh image viewer";
    config = mkIf config.dotfiles.programs.feh.enable {
      programs.feh = {
        enable = true;
        keybindings = {
          prev_img = ["h" "Left"];
          next_img = ["l" "Right"];
          zoom_in = ["j" "Down"];
          zoom_out = ["k" "Up"];
        };
        themes = {
          booth = ["--full-screen" "--hide-pointer" "--slideshow-delay" "20"];
          feh = ["--image-bg" "black"];
          imagemap = ["--quiet" "--recursive" "--verbose" "--thumb-width" "40" "--thumb-height" "30" "--index-info" "%n\\n%wx%h"];
          present = ["--full-screen" "--sort" "name" "--hide-pointer"];
          webcam = ["--multiwindow" "--reload" "20"];
        };
      };
    };
  };
}
