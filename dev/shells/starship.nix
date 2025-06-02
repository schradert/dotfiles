{
  dotfiles.home-manager = {
    config,
    lib,
    ...
  }: let
    inherit (config.programs) starship;
  in {
    options.dotfiles.programs.starship.enable = lib.mkEnableOption "Starship";
    config = lib.mkIf starship.enable {
      dotfiles.programs.elvish.integrations = ["${lib.getExe starship.package} init elvish"];
      dotfiles.programs.xonsh.initExtra = "execx($(${lib.getExe starship.package} init xonsh))";
      programs.starship.enable = true;
    };
  };
}
