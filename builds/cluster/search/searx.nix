{
  perSystem.canivete.arion.modules.searx.services.searx = {
    nixos.configuration.services.searx = {
      enable = true;
      redisCreateLocally = true;
      runInUwsgi = true;
      # TODO what are all the settings I want?
      # NOTE https://github.com/NixOS/nixpkgs/blob/nixos-unstable/nixos/modules/services/networking/searx.nix
      # NOTE https://searx.github.io/searx/admin/settings.html
      # NOTE https://github.com/searxng/searxng/blob/master/searx/botdetection/limiter.toml
      # settings = {};
      # environmentFile = ./path;
      # settingsFile = ./yaml;
      # limiterSettings = {};
      # uwsgiConfig = {};
    };
    nixos.useSystemd = true;
  };
}
