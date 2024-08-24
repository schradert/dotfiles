{
  perSystem.dotfiles.helm.volsync = {
    namespace = "kube-system";
    chart = {
      repo = "https://backube.github.io/helm-charts";
      chart = "volsync";
      version = "0.10.0";
      sha256 = "LnAeoCsA/oHoR0jZWVb9dw0YXuThS3LqoX40Q/8Lh9c=";
    };
    values.metrics.disableAuth = true;
  };
}
