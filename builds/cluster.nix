{
  config,
  nix,
  ...
}: {
  perSystem.canivete.kubenix.clusters.prod = {
    deploy.fetchKubeconfig = "ssh sirver sudo k3s kubectl config view --raw | sed 's/127\.0\.0\.1/${config.dotfiles.domain}/'";
    modules.main = {
      kubenix,
      pkgs,
      ...
    }: {
      kubernetes.resources.namespaces = nix.flip nix.genAttrs (_: {}) [
        "actualbudget"
        "traefik"
        "prometheus"
        "seaweedfs"
        "oauth2-proxy"
        "forgejo"
      ];
      kubernetes.helm.releases = {
        actualbudget = {
          includeCRDs = true;
          namespace = "actualbudget";
          chart = pkgs.stdenv.mkDerivation rec {
            inherit (src) name;
            src = kubenix.lib.helm.fetch {
              repo = "https://beluga-cloud.github.io/charts";
              chart = "actual";
              version = "2.0.0";
              sha256 = "NZ+886bgZwg5CotPqs1IyiJKUmWrsRPiFzEeOAUXpnQ=";
            };
            # Can't verify schema over the internet during build
            # TODO patch to verify using schema definition file paths
            buildPhase = ''
              mkdir -p $out
              cp -r $src/* $out
              rm -f $out/values.schema.*
            '';
          };
        };
        traefik = {
          includeCRDs = true;
          namespace = "traefik";
          chart = kubenix.lib.helm.fetch {
            repo = "https://traefik.github.io/charts";
            chart = "traefik";
            version = "28.3.0";
            sha256 = "wRo7HRQpYF8Om6EwcOd7Krc12uJgElYgrY/xN1j0UNk=";
          };
        };
        prometheus-operator-crds = {
          includeCRDs = true;
          namespace = "prometheus";
          chart = kubenix.lib.helm.fetch {
            repo = "https://prometheus-community.github.io/helm-charts";
            chart = "prometheus-operator-crds";
            version = "13.0.1";
            sha256 = "zP9w37QTe9VwaS+1TcX0SntrmGgGFYpl6L5S7bYF1h0=";
          };
        };
        kube-prometheus-stack = {
          includeCRDs = true;
          namespace = "prometheus";
          chart = kubenix.lib.helm.fetch {
            repo = "https://prometheus-community.github.io/helm-charts";
            chart = "prometheus-operator-crds";
            version = "13.0.1";
            sha256 = "zP9w37QTe9VwaS+1TcX0SntrmGgGFYpl6L5S7bYF1h0=";
          };
        };
        seaweedfs = {
          includeCRDs = true;
          namespace = "seaweedfs";
          chart = kubenix.lib.helm.fetch {
            repo = "https://seaweedfs.github.io/seaweedfs/helm";
            chart = "seaweedfs";
            version = "4.0.0";
            sha256 = "sjO8q4CDhx7Gw3KFqDxIIrZ4lxBzpMu/oC+huH89Iuk=";
          };
          # TODO is this still necessary for it to work on bare metal??
          # values = let
          #   root = "/var/lib/seaweedfs";
          # in {
          #   master.data.hostPathPrefix = "${root}/ssd";
          #   master.logs.hostPathPrefix = "${root}/storage";
          #   volume.data.hostPathPrefix = "${root}/storage";
          #   volume.idx.hostPathPrefix = "${root}/ssd";
          #   volume.logs.hostPathPrefix = "${root}/storage";
          #   volume.dir = "${root}/data";
          #   filer.data.hostPathPrefix = "${root}/storage";
          #   filer.logs.hostPathPrefix = "${root}/storage";
          # };
        };
        oauth2-proxy = {
          includeCRDs = true;
          namespace = "oauth2-proxy";
          chart = kubenix.lib.helm.fetch {
            repo = "https://oauth2-proxy.github.io/manifests";
            chart = "oauth2-proxy";
            version = "7.7.8";
            sha256 = "Cz+TVaM2GBDklRRWMrrRkX3sjywQEz44mlQRhDgLhx4=";
          };
        };
        forgejo = {
          includeCRDs = true;
          namespace = "forgejo";
          chart = kubenix.lib.helm.fetch {
            chartUrl = "oci://code.forgejo.org/forgejo-helm/forgejo";
            chart = "forgejo";
            version = "7.0.1";
            sha256 = "53TnACzIxvukPltumfqk8Cpofur5+8OaTQCPfGhasKs=";
          };
        };
      };
    };
  };
}
