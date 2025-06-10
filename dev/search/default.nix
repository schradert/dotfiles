{
  dotfiles.home-manager = {
    config,
    lib,
    pkgs,
    ...
  }: {
    home.packages = with pkgs; [
      cheat
      python3Packages.howdoi
      ripgrep
      sherlock
      # TODO compare features I use with outfieldr
      tealdeer
      thefuck
      wiki-tui
    ];
    dotfiles.programs = let
      navi' = lib.getExe config.programs.navi.package;
    in {
      elvish.integrations = ["${navi'} widget elvish | slurp"];
      nushell.integrations.navi = "${navi'} widget nushell";
      # TODO build xontrib-navi under xonsh scope
      xonsh.packages = ps: [ps.xontrib-navi];
      xonsh.xontribs = ["navi"];
    };
    # TODO is it possible to add navi as a zellij widget like you can for tmux?
    # TODO add theming!
    programs.navi.enable = true;
    programs.navi.autoupdate.enable = true;
  };
}
