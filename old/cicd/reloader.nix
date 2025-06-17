{
  dotfiles = {
    config,
    lib,
    ...
  }: {
    options.services.reloader.enable = lib.mkEnableOption "reloader";
    config = lib.mkIf config.services.reloader.enable {
      nixos = {pkgs, ...}: {
        canivete.kubernetes.images.reloader = pkgs.dockerTools.pullImage {
          imageName = "ghcr.io/stakater/reloader";
          imageDigest = "sha256:61e2cd350a366059b19d922badfd2a1b35a3f5ee7b872c43d9853c27387637fb";
          hash = "sha256-LW/UulbAw/5nu7jJVuidK5KfPcWxl/uisuv7DM4fVBw=";
          finalImageTag = "v1.3.0";
        };
      };
      kubenix = {helm, ...}: {
        kubernetes.helm.releases.reloader = {
          namespace = "cicd";
          chart = helm.fetch {
            chartUrl = "oci://ghcr.io/stakater/charts/reloader";
            chart = "reloader";
            version = "2.0.0";
            sha256 = "sha256-4CZBHcYEobVSqBWJg6bNRKi5iGgzwYP6N+PtUL6Zfy0=";
          };
        };
      };
    };
  };
}
