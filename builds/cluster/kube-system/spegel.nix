{
  # https://github.com/spegel-org/spegel
  perSystem.dotfiles.helm.spegel = {
    namespace = "kube-system";
    chart = {
      chartUrl = "oci://ghcr.io/spegel-org/helm-charts/spegel";
      chart = "spegel";
      version = "v0.0.23";
      sha256 = "JJBUCtvwSffZ1BKmiUD2asTdSXNsIIYz68ceCeSSMGI=";
    };
    values = {
      grafanaDashboard.enabled = true;
      serviceMonitor.enabled = true;
      spegel.appendMirrors = true;
      # TODO is this what I need to do for podman? why under 30000?
      spegel.containerdRegistryConfigPath = "/etc/cri/conf.d/hosts";
      service.registry.hostPort = 29999;
    };
  };
}
