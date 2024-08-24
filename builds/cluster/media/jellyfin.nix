{
  # TODO figure out hardware acceleration and nodeAffinity
  # TODO find a good helm chart or roll with app-template
  # NOTE https://gitlab.com/bunkbed/backbone/-/blob/migrate-to-on-prem/src/cluster/jellyfin.nix?ref_type=heads
  # NOTE https://jellyfin.org/docs/general/administration/configuration
  perSystem.canivete.arion.modules.jellyfin.services.jellyfin = {
    nixos.configuration.services = {
      jellyfin.enable = true;
      jellyfin.openFirewall = true;
      jellyseer.enable = true;
      jellyseer.openFirewall = true;
    };
    nixos.useSystemd = true;
  };
}
