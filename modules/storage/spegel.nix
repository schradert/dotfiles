{
  dotfiles = {
    config,
    lib,
    ...
  }: let
    inherit (lib) mkEnableOption mkForce mkIf toList;
  in {
    options.services.spegel.enable = mkEnableOption "spegel";
    config = mkIf config.services.spegel.enable {
      nixos = {pkgs, ...}: {
        canivete.kubernetes.k3s.embedded-registry = true;
        environment.etc."rancher/k3s/registries.yaml".source = (pkgs.formats.yaml {}).generate "registries.yaml" {mirrors."*" = {};};
        # TODO is this custom containerd template necessary?
        # NOTE Can't use {{ template "base" . }} to inject 'discard_unpacked_layers' because it gives a "duplicate table" error
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
        # Every node in the cluster before Spegel deployment needs to have the image available
        services.k3s.images = [
          (pkgs.dockerTools.pullImage {
            imageName = "ghcr.io/spegel-org/spegel";
            imageDigest = "sha256:7cec52c7c42cbff593087b6f3645bb58a7e1f1a5b861d767d062ce22533f9394";
            hash = "sha256-rrvpS2EaG2zXkFSMnIhlZr4MiwmY7GPMTmBX5HaMNwg=";
          })
        ];
      };
      kubenix = {helm, ...}: {
        kubernetes.resources.kappconfig.kapp.changeGroupBindings = toList {
          name = "after-spegel";
          resourceMatchers = toList {
            notMatcher.matcher.anyMatcher.matchers = [
              {hasAnnotationMatcher.keys = ["kapp.k14s.io/change-group.spegel"];}
              {hasAnnotationMatcher.keys = ["kapp.k14s.io/change-group.cilium"];}
            ];
          };
        };
        kubernetes.helm.releases.spegel = {
          namespace = "storage";
          chart = helm.fetch {
            chartUrl = "oci://ghcr.io/spegel-org/helm-charts/spegel";
            chart = "spegel";
            version = "0.1.1";
            sha256 = "sha256-jffUpkml7CCHks1GqxIwrAklo9IpJemhiXPiBte5oxU=";
          };
          overrides = toList {
            metadata.annotations."kapp.k14s.io/change-group.spegel" = "spegel";
            metadata.annotations."kapp.k14s.io/change-rule.spegel" = "upsert before upserting after-spegel";
          };
          values = {
            image.tag = "latest";
            image.digest = "";
            spegel.containerdSock = "/run/k3s/containerd/containerd.sock";
            spegel.containerdContentPath = "/var/lib/rancher/k3s/agent/containerd/io.containerd.content.v1.content";
            spegel.containerdRegistryConfigPath = "/var/lib/rancher/k3s/agent/etc/containerd/certs.d";
            # TODO ordering cycle?
            # serviceMonitor.enabled = true;
          };
        };

        # Overrides
        kubernetes.api.resources.apps.v1.DaemonSet.spegel.spec.template.spec.containers.registry.env.GOMEMLIMIT.valueFrom.resourceFieldRef.divisor = mkForce "1";
      };
    };
  };
}
