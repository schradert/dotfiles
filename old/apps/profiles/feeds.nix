{
  dotfiles.home-manager = {
    config,
    lib,
    pkgs,
    ...
  }: {
    config = lib.mkIf config.dotfiles.profiles.client.enable {
      programs.doom-emacs.tangle.init.app.rss = true;
      programs.doom-emacs.extraPackages = e: [e.elfeed-protocol];
      home.packages = with pkgs; [
        circumflex
        russ
        so
        tuir
        tut
      ];
    };
  };
}
