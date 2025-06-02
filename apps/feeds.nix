{
  dotfiles.home-manager = {pkgs, ...}: {
    dotfiles.programs.emacs.orgFiles = [./rss.org];
    home.packages = with pkgs; [
      circumflex
      russ
      so
      tuir
      tut
    ];
  };
}
