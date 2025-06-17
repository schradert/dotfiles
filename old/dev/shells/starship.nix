{
  dotfiles.home-manager = {
    config,
    lib,
    ...
  }: let
    starship = lib.getExe config.programs.starship.package;
  in {
    dotfiles.programs.elvish.integrations = ["${starship} init elvish"];
    dotfiles.programs.xonsh.initExtra = "execx($(${starship} init xonsh))";
    programs.starship.enable = true;
  };
}
