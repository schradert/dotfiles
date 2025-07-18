{
  perSystem.canivete.pre-commit.settings.hooks.lychee.toml.exclude = ["https://k8tz.github.io/k8tz"];
  dotfiles = {
    config,
    lib,
    ...
  }: let
    inherit (config) services;
    inherit (lib) mkEnableOption mkForce mkIf mkMerge toList;
    image = {
      imageName = "quay.io/k8tz/k8tz";
      imageDigest = "sha256:58b3616bf2a196e57d81b4ee65f35d332069e7acc3de679c59aee5aae12eed23";
      hash = "sha256-TxNt20MA/ZW363bRE3IBg4mW+pOV1b3PtSWv5187rYY=";
      finalImageTag = "0.18.0";
    };
  in {
    options.services.k8tz.enable = mkEnableOption "k8tz";
    config = mkIf config.services.k8tz.enable {
      nixos = {pkgs, ...}: {canivete.kubernetes.images.k8tz = pkgs.dockerTools.pullImage image;};
      nixidy = {lib, ...}: {
        applications.k8tz = {
          namespace = "kube-system";
          helm.releases.k8tz = {
            chart = lib.helm.downloadHelmChart {
              chart = "k8tz";
              version = "0.18.0";
              repo = "https://k8tz.github.io/k8tz";
              chartHash = "sha256-1tVEge/+dQVU5jn27staGdEpWXDUGyr/GnC5fPLZhhg=";
            };
            values = mkMerge [
              {
                namespace = null;
                timezone = "America/Los_Angeles";
                cronJobTimeZone = true;
                image.repository = image.imageName;
                image.pullPolicy = "Never";
                image.tag = image.finalImageTag;
                affinity.podAntiAffinity.preferredDuringSchedulingIgnoredDuringExecution = toList {
                  weight = 1;
                  podAffinityTerm.labelSelector.matchLabels."app.kubernetes.io/name" = "k8tz";
                  podAffinityTerm.topologyKey = "kubernetes.io/hostname";
                };
              }
              (mkIf services.cert-manager.enable {
                webhook.certManager.enabled = true;
                webhook.certManager.issuerRef = {
                  name = "k8tz-webhook-issuer";
                  kind = "Issuer";
                };
              })
            ];
          };
          resources = mkMerge [
            # The health-test pod runs before the service is ready, so we force it to retry
            {pods.k8tz-health-test.spec.restartPolicy = mkForce "OnFailure";}
            (mkIf services.cert-manager.enable {issuers.k8tz-webhook-issuer.spec.selfSigned = {};})
          ];
        };
      };
    };
  };
}
