{config, nix, ...}: with nix; {
  # https://github.com/jorenn92/Maintainerr
  perSystem.dotfiles.helm.maintainerr = {
    namespace = "arr";
    values = {
      controllers.maintainerr.containers.maintainerr = {
        image.repository = "ghcr.io/jorenn92/maintainerr";
        image.tag = "2.0.4@sha256:c590387b72e74852cfe83ed2f512f6582653d458c54ee9cfb71210d5f587eaad";
        probes.liveness.enabled = true;
        probes.readiness.enabled = true;
        probes.startup.enabled = true;
      };
      service.maintainerr.controller = "maintainerr";
      service.maintainerr.ports.http.port = 6246;
      ingress.maintainerr.className = "internal";
      ingress.maintainerr.hosts = toList {
        host = "maintainerr.${config.dotfiles.domain}";
        paths = toList {
          path = "/";
          service.identifier = "maintainerr";
          service.port = "http";
        };
      };
    };
  };
}
