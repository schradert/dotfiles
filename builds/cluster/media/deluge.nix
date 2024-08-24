{
  # TODO find a good kubernetes deployment strategy
  perSystem.canivete.arion.modules.deluge.services.deluge = {
    nixos.configuration.services.deluge = {
      web.enable = true;
      web.openFirewall = true;
      enable = true;
      declarative = true;
      openFirewall = true;
      # TODO how do I ensure that this is as secure as possible
      # TODO configuration
      # NOTE https://git.deluge-torrent.org/deluge/tree/deluge/core/preferencesmanager.py#n41
      # config = {};
      # TODO authentication
      # NOTE https://dev.deluge-torrent.org/wiki/UserGuide/Authentication
      # authFile = ./path;
    };
    nixos.useSystemd = true;
  };
}
