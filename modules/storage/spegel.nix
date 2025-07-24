{
  dotfiles = {
    config,
    lib,
    ...
  }: let
    inherit (config) services;
    inherit (lib) mkEnableOption mkForce mkIf;
    image = {
      imageName = "ghcr.io/spegel-org/spegel";
      imageDigest = "sha256:4f9f7cf0b8006f2a17599f0a9f2fa6c02c7a206726f2a89ca26c42622346d17f";
      sha256 = "sha256-8APlI4afYvU/CO8LKN0Lsj9JJOBniWV9qjQh/mo7FJ8=";
      finalImageTag = "v0.3.0";
    };
    k3sSandboxImage = {
      imageName = "rancher/mirrored-pause";
      imageDigest = "sha256:74c4244427b7312c5b901fe0f67cbc53683d06f4f24c6faee65d4182bf0fa893";
      sha256 = "sha256-IbuPXoalV8gKCZGMteRzkeG65o4GCu3G+UX+lVLAo2I=";
      finalImageTag = "3.6";
    };
  in {
    options.services.spegel.enable = mkEnableOption "spegel";
    config = mkIf services.spegel.enable {
      nixos = {config, pkgs, ...}: let
        toml = name: content: builtins.toString ((pkgs.formats.toml {}).generate name content);
      in {
        config = mkIf config.dotfiles.profiles.server.enable {
          # TODO only for server nodes
          # canivete.kubernetes.k3s = mkIf (config.services.k3s.role == "server") {embedded-registry = true;};
          environment.etc."rancher/k3s/registries.yaml".source = (pkgs.formats.yaml {}).generate "registries.yaml" {mirrors."*" = {};};
          # TODO is the embedded version more performant and flexible? why wouldn't embedded-registry work?!
          # NOTE https://github.com/k3s-io/k3s/discussions/9971
          # NOTE Can't use {{ template "base" . }} to inject 'discard_unpacked_layers' because it gives a "duplicate table" error
          # NOTE containerd 2.0 should use a version 3 template
          systemd.tmpfiles.settings."10-k3s" = {
            "/var/lib/rancher/k3s/agent/etc/containerd/certs.d/_default/hosts.toml"."L+".argument = toml "hosts.toml" {
              host."http://127.0.0.1:30020".capabilities = ["pull" "resolve"];
              host."http://127.0.0.1:30021".capabilities = ["pull" "resolve"];
            };
            "/var/lib/rancher/k3s/agent/etc/containerd/config-v3.toml.tmpl"."L+".argument = builtins.toString (pkgs.writeText "config-v3.toml.tmpl" ''
              version = 3
              root = "/var/lib/rancher/k3s/agent/containerd"
              state = "/run/k3s/containerd"

              [grpc]
                address = "/run/k3s/containerd/containerd.sock"

              [plugins.'io.containerd.internal.v1.opt']
                path = "/var/lib/rancher/k3s/agent/containerd"

              [plugins.'io.containerd.grpc.v1.cri']
                stream_server_address = "127.0.0.1"
                stream_server_port = "10010"

              [plugins.'io.containerd.cri.v1.runtime']
                enable_selinux = true
                enable_unprivileged_ports = true
                enable_unprivileged_icmp = true
                device_ownership_from_security_context = false

              [plugins.'io.containerd.cri.v1.images']
                snapshotter = "overlayfs"
                disable_snapshot_annotations = true
                discard_unpacked_layers = false

              [plugins.'io.containerd.cri.v1.images'.pinned_images]
                sandbox = "rancher/mirrored-pause:3.6"

              [plugins.'io.containerd.cri.v1.runtime'.containerd.runtimes.runc]
                runtime_type = "io.containerd.runc.v2"

              [plugins.'io.containerd.cri.v1.runtime'.containerd.runtimes.runc.options]
                SystemdCgroup = true

              [plugins.'io.containerd.cri.v1.runtime'.containerd.runtimes.runhcs-wcow-process]
                runtime_type = "io.containerd.runhcs.v1"

              [plugins.'io.containerd.cri.v1.images'.registry]
                config_path = "/var/lib/rancher/k3s/agent/etc/containerd/certs.d"
            '');
          };
          # Every node in the cluster before Spegel deployment needs to have the image available
          services.k3s.images = builtins.map pkgs.dockerTools.pullImage [image k3sSandboxImage];
        };
      };
      nixidy = {lib, ...}: {
        applications.spegel = {
          namespace = "storage";
          helm.releases.spegel = {
            chart = lib.helm.downloadHelmChart {
              repo = "oci://ghcr.io/spegel-org/helm-charts";
              chart = "spegel";
              version = "0.3.0";
              chartHash = "sha256-KsuZvpTAV4KM4NoOctzclHZt+KUudupM44QwGFC1BzA=";
            };
            values = {
              image.pullPolicy = "Never";
              image.repository = image.imageName;
              image.tag = image.finalImageTag;
              image.digest = "";
              # TODO can I not specify digest?
              # image.digest = image.imageDigest;
              spegel = {
                containerdContentPath = "/var/lib/rancher/k3s/agent/containerd/io.containerd.content.v1.content";
                containerdMirrorAdd = false;
                containerdRegistryConfigPath = "/var/lib/rancher/k3s/agent/etc/containerd/certs.d";
                containerdSock = "/run/k3s/containerd/containerd.sock";
              };
              serviceMonitor.enabled = services.prometheus.enable;
            };
          };
          resources.daemonSets.spegel.spec.template.spec.containers.registry.env.GOMEMLIMIT.valueFrom.resourceFieldRef.divisor = lib.mkForce "1";
        };
      };
    };
  };
}
