{
  # Sabnzbd only supports unrar currently, but unar is a better alternative to keep track of
  # NOTE https://github.com/sabnzbd/sabnzbd/issues/1120
  canivete.pkgs.allowUnfree = ["unrar"];
  dotfiles = {
    canivete,
    config,
    lib,
    ...
  }: let
    inherit (lib) concatStringsSep mkEnableOption mkIf toList mapAttrs flip pipe;
    port = 8080;
    subdomain = "sabnzbd.${config.domain}";
    image = {
      imageName = "";
      imageDigest = "";
      hash = "";
      finalImageTag = "";
    };
  in {
    options.services.sabnzbd.enable = mkEnableOption "sabnzbd";
    config = mkIf config.services.sabnzbd.enable {
      nixos = {pkgs, ...}: {canivete.kubernetes.images.sabnzbd = pkgs.dockerTools.pullImage image;};
      kubenix.kubernetes.helm.releases.sabnzbd = {
        namespace = "media";
        values = {
          controllers.sabnzbd.containers.sabnzbd = {
            image.repository = image.imageName;
            image.tag = image.finalImageTag;
            envFrom = [
              {secret = "sabnzbd";}
              {configMapRef.name = "sabnzbd";}
            ];
            probes.liveness.enabled = true;
            probes.readiness.enabled = true;
            probes.startup.enabled = true;
          };
          service.sabnzbd.controller = "sabnzbd";
          service.sabnzbd.ports.http.port = port;
          ingress.sabnzbd.className = "internal";
          ingress.sabnzbd.hosts = toList {
            host = subdomain;
            paths = toList {
              path = "/";
              service.identifier = "sabnzbd";
              service.port = "http";
            };
          };
          secrets.sabnzbd.data = mapAttrs (_: flip pipe [canivete.vals.sops.default canivete.toBase64]) {
            # TODO create and store these API keys
            SABNZBD__API_KEY = "";
            SABNZBD__NZB_KEY = "";
          };
          configMaps.sabnzbd.data = {
            SABNZBD__PORT = toString port;
            SABNZBD__HOST_WHITELIST_ENTRIES = concatStringsSep "," [
              "sabnzbd"
              "sabnzbd.media"
              "sabnzbd.media.svc"
              "sabnzbd.media.svc.cluster"
              "sabnzbd.media.svc.cluster.local"
              subdomain
            ];
          };
        };
      };
    };
  };
}
