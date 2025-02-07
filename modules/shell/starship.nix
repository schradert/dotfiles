{
  # TODO dracula theme for starship
  # TODO catpuccin theme for starship
  canivete.deploy.system.homeModules.starship = {
    config,
    lib,
    ...
  }: let
    inherit (config.programs) starship;
  in {
    config = lib.mkIf starship.enable {
      dotfiles.programs.elvish.integrations = ["${lib.getExe starship.package} init elvish"];
      dotfiles.programs.xonsh.initExtra = "execx($(${lib.getExe starship.package} init xonsh))";
    };
  };
}
