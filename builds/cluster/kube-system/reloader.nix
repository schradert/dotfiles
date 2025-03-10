{
  # https://github.com/stakater/Reloader
  perSystem.canivete.kubenix.helm.reloader = {
    namespace = "kube-system";
    chart = {
      chartUrl = "oci://ghcr.io/stakater/charts/reloader";
      chart = "reloader";
      version = "1.0.121";
      sha256 = "ioCx1TxXSDCq6J06AZZecIsO25vjokjSyA9CFUwBJfw=";
    };
    values = {
      fullnameOverride = "reloader";
      reloader.readOnlyRootFileSystem = true;
      reloader.podMonitor.enabled = true;
      reloader.podMonitor.namespace = "kube-system";
    };
  };
}
