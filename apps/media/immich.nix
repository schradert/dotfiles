{
  dotfiles = {
    config,
    lib,
    ...
  }: {
    options.services.immich.enable = lib.mkEnableOption "Immich";
    config = lib.mkIf config.services.immich.enable {
      # TODO add images to NixOS
      kubenix = {helm, ...}: {
        kubernetes.helm.releases.immich = {
          namespace = "media";
          chart = helm.fetch {
            repo = "https://immich-app.github.io/immich-charts";
            chart = "immich";
            version = "0.7.1";
            sha256 = "85dZNeRKUR3b6QB/iHZQLtp4cwEirixZ6E2rpLD68EE=";
          };
          extraResources.persistentVolumeClaims.immich = {
            metadata.namespace = "immich";
            spec.accessModes = ["ReadWriteOnce"];
            spec.resources.requests.storage = "10Gi";
          };
          values = {
            immich.persistence.library.existingClaim = "immich";
            # TODO convert to postgres operator!
            postgresql.enabled = true;
            redis.enabled = true;
          };
        };
      };
    };
  };
}
