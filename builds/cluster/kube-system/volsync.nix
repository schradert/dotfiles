{nix, ...}: {
  perSystem.dotfiles.opentofu.passwords = {
    b2-restic.length = 21;
    ceph-restic.length = 21;
  };
  perSystem.dotfiles.helm.volsync = {
    namespace = "kube-system";
    chart = {
      repo = "https://backube.github.io/helm-charts";
      chart = "volsync";
      version = "0.10.0";
      sha256 = "LnAeoCsA/oHoR0jZWVb9dw0YXuThS3LqoX40Q/8Lh9c=";
    };
    values.manageCRDs = true;
    values.metrics.disableAuth = true;
    resources.secrets.volsync-restic-passwords.stringData = {
      B2_RESTIC = nix.vals.sops "default.yaml#/passwords/b2-restic";
      CEPH_RESTIC = nix.vals.sops "default.yaml#/passwords/ceph-restic";
    };
  };
}
