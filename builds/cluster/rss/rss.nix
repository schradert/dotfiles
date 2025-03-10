{
  # TODO choose an rss server
  # NOTE https://github.com/ncarlier/feedpushr
  # NOTE https://github.com/DIYgod/RSSHub
  # NOTE https://github.com/RSS-Bridge/rss-bridge
  # TODO choose an rss web reader
  # NOTE https://github.com/ncarlier/readflow
  # TODO choose an rss gui reader
  # TODO add feeds to rss aggregator
  # NOTE rpgcodex
  # NOTE add feeds for my filters on [Stack Exchange](https://stackexchange.com/users/15556329/t-whiz?tab=accounts)
  # NOTE convert websites like [this bash issue](https://savannah.gnu.org/support/?108134) into rss feed
  # NOTE contents of rss.org
  canivete.deploy.system.homeModules.rss = {
    config,
    lib,
    pkgs,
    ...
  }: {
    config = lib.mkIf config.dotfiles.workstation.enable {
      # TODO build syndicationd https://github.com/ymgyt/syndicationd
      # TODO compare russ vs syndicationd TUI
      home.packages = with pkgs; [russ];
      dotfiles.programs.emacs.orgFiles = [./rss.org];
    };
  };
}
