{config, nix, ...}: with nix; let
  port = 8888;
  metricsPort = 8080;
  inherit (config.dotfiles) domain;
in {
  # [ ] [atuin](https://github.com/atuinsh/atuin) can i synchronize over all computers?
  perSystem.dotfiles.nix2container.atuin = {};
  perSystem.dotfiles.helm.atuin.values = {
    controllers.atuin.containers.atuin = {
      image.repository = "ref+envsubst://ATUIN_IMAGE_FULLREPOSITORY+";
      image.tag = "ref+envsubst://ATUIN_IMAGE_TAG";
      args = ["server" "start"];
      envFrom = [
        {secret = "atuin";}
        {configMapRef.name = "atuin";}
      ];
      probes.liveness.enabled = true;
      probes.readiness.enabled = true;
      probes.startup.enabled = true;
    };
    secrets.atuin.enabled = true;
    secrets.atuin.stringData = {};
    configMaps.atuin.enabled = true;
    configMaps.atuin.data = {
      ATUIN_HOST = "0.0.0.0";
      ATUIN_PORT = toString port;
      ATUIN_OPEN_REGISTRATION = "true";
      ATUIN_TLS__ENABLE = "false";
      ATUIN_METRICS__ENABLE = "true";
      ATUIN_METRICS__HOST = "0.0.0.0";
      ATUIN_METRICS__PORT = toString metricsPort;
    };
    service.atuin.controller = "atuin";
    service.atuin.ports = {
      http.primary = true;
      http.port = port;
      metrics.port = metricsPort;
    };
    serviceMonitor.atuin.serviceName = "atuin";
    serviceMonitor.atuin.endpoints = toList {
      port = "metrics";
      scheme = "http";
      path = "/metrics";
    };
    ingress.atuin.className = "internal";
    ingress.atuin.hosts = toList {
      host = "atuin.${domain}";
      paths = toList {
        path = "/";
        service.identifier = "atuin";
        service.port = "http";
      };
    };
  };
}
