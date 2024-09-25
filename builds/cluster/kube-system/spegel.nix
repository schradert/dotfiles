{
  # https://github.com/spegel-org/spegel
  canivete.deploy.nixos.modules.spegel = {config, lib, pkgs, ...}: {
    config = lib.mkIf config.dotfiles.kubernetes.enable {
      # dotfiles.kubernetes.k3s.embedded-registry = lib.mkIf (config.services.k3s.role == "server") true;
      # environment.etc."rancher/k3s/registries.yaml".source = pkgs.writers.writeYAML "registries.yaml" {mirrors."*" = {};};
      # Can't use {{ template "base" . }} to inject 'discard_unpacked_layers' because it gives a "duplicate table" error
      services.k3s.containerdConfigTemplate = ''
        version = 2

        [plugins."io.containerd.internal.v1.opt"]
          path = "/var/lib/rancher/k3s/agent/containerd"

        [plugins."io.containerd.grpc.v1.cri"]
          stream_server_address = "127.0.0.1"
          stream_server_port = "10010"
          enable_selinux = true
          enable_unprivileged_ports = true
          enable_unprivileged_icmp = true
          sandbox_image = "rancher/mirrored-pause:3.6"

        [plugins."io.containerd.grpc.v1.cri".containerd]
          snapshotter = "overlayfs"
          disable_snapshot_annotations = true
          discard_unpacked_layers = false

        [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
          runtime_type = "io.containerd.runc.v2"

        [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
          SystemdCgroup = true

        [plugins."io.containerd.grpc.v1.cri".registry]
          config_path = "/var/lib/rancher/k3s/agent/etc/containerd/certs.d"
      '';
    };
  };
  perSystem.dotfiles.helm.spegel = {
    namespace = "kube-system";
    chart = {
      chartUrl = "oci://ghcr.io/spegel-org/helm-charts/spegel";
      chart = "spegel";
      version = "v0.0.24";
      sha256 = "5RDhU2md61UvFVE4uz+tMTdEWFXHfSfgAKzMz7qBzCI=";
    };
    values.spegel = {
      appendMirrors =  true;
      containerdSock = "/run/k3s/containerd/containerd.sock";
      containerdRegistryConfigPath = "/var/lib/rancher/k3s/agent/etc/containerd/certs.d";
    };
    values.service.registry.hostPort = 29999;
    values.serviceMonitor.enabled = true;
  };
}
