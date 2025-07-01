{
  perSystem.canivete.pre-commit.settings.hooks.lychee.toml.exclude = ["https://charts.crossplane.io/master"];
  dotfiles = {
    config,
    lib,
    ...
  }: let
    inherit (config) services;
    inherit (lib) mapAttrs mkEnableOption mkIf;
    images = {
      crossplane = {
        imageName = "xpkg.crossplane.io/crossplane/crossplane";
        imageDigest = "sha256:43204c187b06bdce8ab387743a2ab7c4c57fcf01f951e980af5bcdea5514de6a";
        hash = "sha256-GvEoFTsK1TCz08jnaoVbc5CrvMIOh4FfM65KO9PyyL0=";
        finalImageTag = "v2.0.0-rc.0.108.g3ce6a1399";
      };
    };
  in {
    options.services.crossplane.enable = mkEnableOption "crossplane";
    config = mkIf config.services.crossplane.enable {
      nixos = {pkgs, ...}: {canivete.kubernetes.images = mapAttrs (_: pkgs.dockerTools.pullImage) images;};
      kubenix = {helm, ...}: {
        canivete.ifd.crds.providers = "pkg.crossplane.io/v1/Provider";
        kubernetes.helm.releases.crossplane = {
          namespace = "cicd";
          chart = helm.fetch {
            repo = "https://charts.crossplane.io/master";
            chart = "crossplane";
            version = "v2.0.0-rc.0.108.g3ce6a1399";
            sha256 = "sha256-mlWUXSP8509/i0Wz/IpCInTHMjNjPCPLxL6K39vn3zU=";
          };
          values = {
            # TODO why can't this be unmarshalled correctly?
            # customAnnotations = mkIf services.reloader.enable {"reloader.stakater.com/auto" = "true";};
            image.tag = images.crossplane.finalImageTag;
            image.pullPolicy = "Never";
            metrics.enabled = services.prometheus.enable;
            # TODO configure real functionality
            # provider.packages = [];
            # configuration.packages = [];
            # function.packages = [];
          };
        };
      };
    };
  };
}
