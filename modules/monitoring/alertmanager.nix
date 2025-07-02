{
  dotfiles = {
    config,
    lib,
    ...
  }: let
    inherit (lib) mkEnableOption mkIf toList;
    hostname = "alertmanager.${config.domain}";
  in {
    options.services.alertmanager.enable = mkEnableOption "alertmanager";
    config = mkIf config.services.alertmanager.enable {
      nixos = {pkgs, ...}: {
        canivete.kubernetes.images.alertmanager = pkgs.dockerTools.pullImage {
          imageName = "quay.io/prometheus/alertmanager";
          imageDigest = "sha256:27c475db5fb156cab31d5c18a4251ac7ed567746a2483ff264516437a39b15ba";
          hash = "sha256-8ZuCk3GSdCgcWGkOm1lvVeCVywCmW3yFy2F4lkGczZM=";
          finalImageTag = "v0.28.1";
        };
      };
      kubenix = {helm, ...}: {
        kubernetes.helm.releases.alertmanager = {
          namespace = "monitoring";
          chart = helm.fetch {
            chart = "alertmanager";
            version = "1.21.0";
            chartUrl = "oci://ghcr.io/prometheus-community/charts/alertmanager";
            sha256 = "sha256-AmEfpH+wzsfWPgtPIVesO7eTmVC0l4E6nXHYLAVj4Xs=";
          };
          values = {
            baseURL = "https" + "://${hostname}";
            # TODO config receivers
            # config = {};
            configmapReload.enabled = true;
            # Version from prometheus deployment
            configmapReload.image.tag = "v0.81.0";
            statefulSet.annotations."reloader.stakater.com/auto" = "true";
          };
          extraResources.httproutes.alertmanager.spec = {
            hostnames = [hostname];
            parentRefs = toList {
              name = "internal";
              namespace = "kube-system";
              sectionName = "https";
            };
            rules = toList {
              backendRefs = toList {
                name = "alertmanager";
                port = "http";
              };
            };
          };
        };
      };
    };
  };
}
