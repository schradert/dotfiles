{
  nix,
  self,
  ...
}:
with nix; let
  namespace = "kube-system";
  chart = {
    repo = "https://postfinance.github.io/kubelet-csr-approver";
    chart = "kubelet-csr-approver";
    version = "1.2.2";
    sha256 = "J+/6oRReQrrGsHEWmfCnxtMNpAgcv8nrkn9L/wenmQM=";
  };
  values = {
    fullnameOverride = "kubelet-csr-approver";
    providerRegex = pipe self.nixosConfigurations [
      (filterAttrs (_: cfg: cfg.config.dotfiles.kubernetes.enable))
      attrNames
      (concatStringsSep "|")
      (str: "^(${str})$")
    ];
    bypassDnsResolution = true;
  };
  release = {inherit namespace chart values;};
in {
  # [ ] [kubelet-csr-approver](https://github.com/postfinance/kubelet-csr-approver)
  perSystem.dotfiles.helm = {
    kubelet-csr-approver-bootstrap = recursiveUpdate release {bootstrap = true;};
    kubelet-csr-approver = recursiveUpdate release {
      values.metrics.enable = true;
      values.metrics.serviceMonitor.enabled = true;
    };
  };
}
