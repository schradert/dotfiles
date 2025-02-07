{
  config,
  lib,
  ...
}: let
  inherit (config.dotfiles) domain;
in {
  # TODO user accounts?
  # TODO what about collaboration with excalidraw-room? https://github.com/excalidraw/excalidraw-room
  # TODO mermaid-to-excalidraw?
  # TODO find a wrapper application!
  perSystem.dotfiles.helm.excalidraw = {
    namespace = "home";
    values = {
      controllers.excalidraw.annotations."reloader.stakater.com/auto" = "true";
      controllers.excalidraw.containers.excalidraw = {
        image.repository = "excalidraw/excalidraw";
        image.tag = "latest@sha256:fae667864717a415e7474b5f757ffb50e63a81cfc1a2fbcf905ecbd137d0dbba";
        probes.liveness.enabled = true;
        probes.readiness.enabled = true;
        probes.startup.enabled = true;
        resources.requests.cpu = "100m";
        resources.requests.memory = "128Mi";
        resources.limits.memory = "512Mi";
      };
      service.excalidraw.controller = "excalidraw";
      service.excalidraw.ports.http.port = 80;
      serviceAccount.create = true;
      ingress.excalidraw = {
        annotations = {
          "external-dns.alpha.kubernetes.io/target" = "external.${domain}";
          "nginx.ingress.kubernetes.io/auth-url" = "https://oauth2-proxy.${domain}/oauth2/auth?allowed_groups=/family";
          "nginx.ingress.kubernetes.io/auth-signin" = "https://oauth2-proxy.${domain}/oauth2/start?rd=$scheme://$host$request_uri";
        };
        className = "external";
        hosts = lib.toList {
          host = "excalidraw.${domain}";
          paths = lib.toList {
            path = "/";
            service.identifier = "excalidraw";
            service.port = "http";
          };
        };
      };
    };
  };
}
