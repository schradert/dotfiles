{
  description = "System configuration";
  inputs = {
    canivete.url = github:schradert/canivete;
    nixpkgs.follows = "canivete/nixpkgs";
    nixpkgs-stable.follows = "canivete/nixpkgs-stable";

    home-manager.url = github:nix-community/home-manager;
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-darwin.url = github:LnL7/nix-darwin;
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-on-droid.url = github:nix-community/nix-on-droid;
    nix-on-droid.inputs.nixpkgs.follows = "nixpkgs";

    systems-default.url = github:nix-systems/x86_64-linux;
    systems-darwin.url = github:nix-systems/aarch64-darwin;

    nixos-flake.url = github:srid/nixos-flake;

    # nix-doom-emacs marked as broken for now
    # TODO keep tabs on this project to see if it's evolving enough to try to use
    nix-doom-emacs.url = github:nix-community/nix-doom-emacs;
    nix-doom-emacs.inputs.nixpkgs.follows = "nixpkgs";
    emacs-overlay.url = github:nix-community/emacs-overlay;
    emacs-overlay.inputs.nixpkgs.follows = "nixpkgs";
    emacs-overlay.inputs.nixpkgs-stable.follows = "nixpkgs-stable";

    terranix.url = github:terranix/terranix;
    terranix.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = github:Mic92/sops-nix;
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.inputs.nixpkgs-stable.follows = "nixpkgs-stable";
    gke-gcloud-auth-plugin-flake.url = github:christian-blades-cb/gke-gcloud-auth-plugin-nix;
    spicetify-nix.url = github:the-argus/spicetify-nix;
    spicetify-nix.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = inputs:
    with inputs;
      canivete.lib.mkFlake {
        inherit inputs;
        everything = [./dev ./programs ./profiles];
      } ({
        config,
        nix,
        ...
      }: {
        imports = [nixos-flake.flakeModule ./work.nix ./deploy.nix ./canivete-deploy.nix];

        domain = "trdos.me";
        root = "sirver";
        people = {
          me = "tristan";
          users.tristan = {
            name = "Tristan Schrader";
            accounts.github = "schradert";
            accounts.gitlab = "schrader.tristan";
            profiles.default.email = "t0rdos@pm.me";
          };
        };
        nixos.sirver.module = {
          dotfiles.kubernetes.enable = true;
          boot.initrd.availableKernelModules = ["ehci_pci" "megaraid_sas" "usbhid"];
        };
        nixos.chilldom.module = {
          dotfiles.graphical.enable = true;
          home-manager.users.tristan.programs.macchina.networkInterface = "enp0s31f6";
          boot.initrd.availableKernelModules = ["xhci_pci" "nvme" "rtsx_pci_sdmmc"];
          powerManagement.cpuFreqGovernor = "powersave";
        };
        droid.boox = {};
        droid.mobile = {};
        perSystem.canivete.devShell.name = "dot";
        perSystem.canivete.kubenix.clusters.prod = {
          deploy.fetchKubeconfig = "ssh sirver sudo k3s kubectl config view --raw | sed 's/127\.0\.0\.1/${config.domain}/'";
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
      });
}
