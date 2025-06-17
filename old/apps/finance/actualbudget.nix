{
  # TODO nix built image
  # TODO persistence + volsync
  # TODO LDAP? with authentication
  # TODO pod.enableServiceLinks?
  # TODO update for multiple user support https://github.com/actualbudget/actual/issues/524
  dotfiles = {
    canivete,
    config,
    lib,
    ...
  }: let
    inherit (lib) mkEnableOption mkIf toList;
    inherit (config) domain;
    subdomain = "actual.${domain}";
    port = 5006;
    image = {
      imageName = "ghcr.io/actualbudget/actual-server";
      imageDigest = "";
      hash = "";
      finalImageTag = "";
    };
  in {
    options.services.actualbudget.enable = mkEnableOption "actualbudget";
    config = mkIf config.services.actualbudget.enable {
      nixos = {pkgs, ...}: {canivete.kubernetes.images.actualbudget = pkgs.dockerTools.pullImage image;};
      opentofu.passwords.actual = {
        length = 21;
        special = false;
      };
      kubenix.kubernetes.helm.releases.actual = {
        namespace = "office";
        values = {
          controllers.actual.annotations."reloader.stakater.com/auto" = "true";
          controllers.actual.containers.actual = {
            image.repository = image.imageName;
            image.tag = image.finalImageTag;
            envFrom = toList {configMapRef.name = "actual";};
            probes.liveness.enabled = true;
            probes.readiness.enabled = true;
            probes.startup.enabled = true;
            resources.requests.cpu = "12m";
            resources.requests.memory = "128Mi";
            resources.limits.memory = "512Mi";
          };
          service.actual.controller = "actual";
          service.actual.ports.http.port = port;
          ingress.actual = {
            annotations = {
              "external-dns.alpha.kubernetes.io/target" = "external.${domain}";
              "nginx.ingress.kubernetes.io/auth-url" = "https://oauth2-proxy.${domain}/oauth2/auth?allowed_emails=me@trdos.me";
              "nginx.ingress.kubernetes.io/auth-signin" = "https://oauth2-proxy.${domain}/oauth2/start?rd=$scheme://$host$request_uri";
              # TODO is this even secure?
              "nginx.ingress.kubernetes.io/auth-snippet" = "proxy_set_header X-Actual-Password ${canivete.vals.sops.default "passwords/actual"}";
              "nginx.ingress.kubernetes.io/auth-response-headers" = "X-Actual-Password";
            };
            className = "external";
            hosts = toList {
              host = subdomain;
              paths = toList {
                path = "/";
                service.identifier = "actual";
                service.port = "http";
              };
            };
          };
          persistence.data.existingClaim = "actual";
          persistence.data.globalMounts = [{path = "/data";}];
          configMaps.actual.data = {
            ACTUAL_PORT = builtins.toString port;
            ACTUAL_LOGIN_METHOD = "header";
          };
        };
      };
    };
  };
}
