{
  dotfiles.home-manager = {
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
