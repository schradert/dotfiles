{
  dotfiles.home-manager = {
    imports = [
      ({
        config,
        lib,
        ...
      }: let
        bin = lib.getExe config.programs.carapace.package;
      in {
        programs.carapace.enable = true;
        dotfiles.programs.elvish.interactiveExtra = "eval (${bin} _carapace elvish | slurp)";
        dotfiles.programs.xonsh.interactiveExtra = "exec($(${bin} _carapace xonsh))";
      })
    ];
    dotfiles.programs.elvish.enable = true;
    dotfiles.programs.xonsh.enable = true;
    programs = {
      doom-emacs.tangle.init.lang.sh = ["+fish"];
      bash.enable = true;
      fish.enable = true;
      nushell.enable = true;
      zsh.enable = true;
    };
  };
}
