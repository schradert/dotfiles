{
  config,
  nix,
  ...
}:
with nix; {
  # https://github.com/autobrr/omegabrr
  perSystem.dotfiles.helm.omegabrr = {
    namespace = "arr";
    values = {
      controllers.omegabrr.containers.omegabrr = {
        image.repository = "ghcr.io/autobrr/omegabrr";
        image.tag = "v1.13.1@sha256:ea3fca614459b6ffa0cd6b86c52195eb2a0705bfe0d9a2d88588afaa83762494";
        probes.liveness.enabled = true;
        probes.readiness.enabled = true;
        probes.startup.enabled = true;
      };
      service.omegabrr.controller = "omegabrr";
      service.omegabrr.ports.http.port = 80;
      ingress.omegabrr.className = "internal";
      ingress.omegabrr.hosts = toList {
        host = "omegabrr.${config.dotfiles.domain}";
        paths = toList {
          path = "/";
          service.identifier = "omegabrr";
          service.port = "http";
        };
      };
    };
  };
}
