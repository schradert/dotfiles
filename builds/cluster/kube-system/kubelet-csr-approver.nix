{
  nix,
  self,
  ...
}:
with nix; {
  # [ ] [kubelet-csr-approver](https://github.com/postfinance/kubelet-csr-approver)
  perSystem.dotfiles.helm.kubelet-csr-approver = {
    namespace = "kube-system";
    chart = {
      repo = "https://postfinance.github.io/kubelet-csr-approver";
      chart = "kubelet-csr-approver";
      version = "1.2.2";
      sha256 = "J+/6oRReQrrGsHEWmfCnxtMNpAgcv8nrkn9L/wenmQM=";
    };
    values = {
      providerRegex = pipe self.nixosConfigurations [
        (filterAttrs (_: cfg: cfg.config.dotfiles.kubernetes.enable))
        attrNames
        (concatStringsSep "|")
        (str: "^(${str})$")
      ];
      bypassDnsResolution = true;
      metrics.enable = true;
      metrics.serviceMonitor.enabled = true;
    };
  };
}
