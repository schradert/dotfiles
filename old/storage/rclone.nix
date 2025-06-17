{
  config,
  lib,
  ...
}: let
  inherit (config.canivete.meta) domain;
  inherit (lib) toList;
  port = 5572;
in {
  # TODO connect to rclone server
  # TODO install rclone tui https://github.com/darkhz/rclone-tui or https://github.com/veeso/termscp
  # TODO should this be an interactive download or a mount?
  # TODO is croc useful?
  dotfiles.home-manager = {pkgs, ...}: {home.packages = with pkgs; [croc rclone];};
  perSystem.canivete.kubenix.clusters.deploy.kubernetes.helm.releases.rclone = {
    namespace = "storage";
    values = {
      controllers.rclone.annotations."reloader.stakater.com/auto" = "true";
      controllers.rclone.containers.rclone = {
        image.repository = "rclone/rclone";
        image.tag = "1.68.2";
        args = ["rcd"];
        envFrom = [{configMapRef.name = "rclone-configmap";}];
        probes.liveness.enabled = true;
        probes.readiness.enabled = true;
        probes.startup.enabled = true;
        resources.requests.cpu = "10m";
        resources.requests.memory = "128Mi";
        resources.limits.memory = "512Mi";
      };
      configMaps.rclone-configmap.data = {
        RCLONE_RC = "true";
        # TODO do I need a hostname for address?
        RCLONE_RC_ADDR = "0.0.0.0:${toString port}";
        RCLONE_RC_ENABLE_METRICS = "true";
        # TODO authenticate for multiple users passed from proxy
        RCLONE_RC_NO_AUTH = "true";
        RCLONE_RC_WEB_GUI = "true";
        RCLONE_RC_WEB_GUI_NO_OPEN_BROWSER = "true";
        # TODO configure ceph, myrient, and all of my cloud drives as backends
        # TODO configure auto-dumping of everything I download from myrient
        # TODO how to avoid duplicate downloads?
      };
      service.rclone.controller = "rclone";
      service.rclone.ports = {
        http.primary = true;
        http.port = port;
        # TODO what is the metrics port?
        metrics.port = 0;
      };
      serviceMonitor.rclone.serviceName = "rclone";
      serviceMonitor.rclone.endpoints = toList {
        # TODO are these the correct defaults?
        port = "metrics";
        scheme = "http";
        path = "/metrics";
        interval = "1m";
        scrapeTimeout = "10s";
      };
      ingress.rclone = {
        annotations."external-dns.alpha.kubernetes.io/target" = "external.${domain}";
        annotations."nginx.ingress.kubernetes.io/auth-url" = "https://oauth2-proxy.${domain}/oauth2/auth?allowed_emails=me@trdos.me";
        annotations."nginx.ingress.kubernetes.io/auth-signin" = "https://oauth2-proxy.${domain}/oauth2/start?rd=$scheme://$host$request_uri";
        className = "external";
        hosts = toList {
          host = "rclone.${domain}";
          paths = toList {
            path = "/";
            service.identifier = "rclone";
            service.port = "http";
          };
        };
      };
    };
  };
}
