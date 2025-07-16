{
  canivete,
  config,
  inputs,
  lib,
  ...
}: let
  inherit (canivete.vals.sops) default;
  inherit (lib) getAttr getExe mapAttrs mkForce;
in {
  # FIXME why is k3s CRASHING?! overloading it with deployment requests at the beginning?
  # FIXME why is nixos_sirver_system failing initial deployment? i have to run twice
  # TODO how should I integrate this
  # TODO why is kubernetes in opentofu showing up sensitive
  # TODO why does openebs-localpv-provisioner fail?
  # NOTE /builds + /modules are just temporary out of store symlinks
  flake.dotfiles = mapAttrs (_: getAttr "dotfiles") config.allSystems;
  flake.overlays.nur = inputs.nur.overlays.default;
  perSystem = {
    pkgs,
    system,
    ...
  }: {
    apps.deploy.program = pkgs.writeShellScriptBin "deploy" "nix run .#canivete.${system}.opentofu.script -- --workspace deploy \"$@\"";
    canivete.pre-commit = {
      languages.shell.enable = true;
      settings.hooks = {
        # Currently I am only committing to trunk now
        no-commit-to-branch.settings.branch = mkForce [];
        # It's not really a shell script, so...
        shellcheck.excludes = [".envrc"];
        # Authenticate with GitHub to avoid harsh rate-limiting on anonymous requests causing lychee to fail
        lychee.settings.flags = "--github-token \"$(${getExe pkgs.gh} auth token)\"";
        # Pretty much never will a hardcoded path be matched
        lychee.toml.exclude = ["file://*" "http://127.0.0.*"];
      };
    };
    # URLs built with substitution
    # TODO error: repetition quantifier expects a valid decimal: "^.+\${.+}.+$"
    # canivete.pre-commit.settings.hooks.lychee.settings.toml.exclude = [];
  };
  canivete.meta.people.users.tristan = {
    name = "Tristan Schrader";
    accounts.github = "schradert";
    accounts.gitlab = "schrader.tristan";
    profiles.default.email = "t0rdos@pm.me";
  };
  dotfiles = {
    domain = "trdos.me";
    me = "tristan";
    people.tristan = "tristan";

    clouds.cloudflare.enable = true;
    storage.bucket = {
      enable = true;
      provider = "backblaze";
      region = "us-west-004";
      user = "004099163b2ee630000000002";
      password = default "backblaze";
    };

    nixos = {pkgs, ...}: {
      # Convenient debugging image to bypass airgap
      canivete.kubernetes.images.nix = pkgs.dockerTools.pullImage {
        imageName = "nixos/nix";
        imageDigest = "sha256:d078d7153763895fce17c5fbbdeb86fcfcac414ca0ba875d413c1df57be19931";
        hash = "sha256-Tuvew+O8CDteF94NWX9pUugA++7UxViJmqR+yPt3H1g=";
        finalImageTag = "2.28.3";
      };
    };
    kubenix.canivete.root = "sirver";
    nixidy = {
      nixidy.target = {
        repository = "https://github.com/schradert/dotfiles.git";
        branch = "main";
      };
      applications.rook-ceph.helm.releases.rook-ceph-cluster.values.cephClusterSpec.storage.nodes = [
        {
          name = "sirver";
          devices = [
            {name = "/dev/disk/by-id/scsi-35000c50067fb404b";}
            {name = "/dev/disk/by-id/scsi-35000c50067fc5df3";}
            {name = "/dev/disk/by-id/scsi-35000c50067fc640b";}
            {name = "/dev/disk/by-id/scsi-35000c50067fcc0d3";}
            {name = "/dev/disk/by-id/scsi-35000c50067fcc2fb";}
            {name = "/dev/disk/by-id/scsi-35000c50067fcd9af";}
            {name = "/dev/disk/by-id/scsi-35000c50067fe560f";}
          ];
        }
        {
          name = "octopus";
          devices = [
            {name = "/dev/disk/by-id/scsi-36b82a720cf60ce002fd94d462aff700b";}
            {name = "/dev/disk/by-id/scsi-36b82a720cf60ce002fd94d552bdede19";}
            {name = "dev/disk/by-id/scsi-36b82a720cf60ce002fd94d622ca764e8";}
            {name = "/dev/disk/by-id/scsi-36b82a720cf60ce002fd94d6f2d66f068";}
            {name = "/dev/disk/by-id/scsi-36b82a720cf60ce002fd94d7c2e2ed82e";}
            {name = "/dev/disk/by-id/scsi-36b82a720cf60ce002fd94d8a2f011f94";}
            {name = "/dev/disk/by-id/scsi-36b82a720cf60ce002fd94d962fc2bcad";}
          ];
        }
      ];
    };

    services = {
      cilium.enable = true;
      coredns.enable = true;
      spegel.enable = true;
      argocd.enable = true;
      external-dns.enable = true;
      cloudflared.enable = true;
      kubelet-csr-approver.enable = true;
      cert-manager.enable = true;
      cert-manager.provider.cloudflare.token = "cloudflare/account/token";

      snapshot-controller.enable = true;
      openebs.enable = true;
      volsync.enable = true;
      postgres.enable = true;
      rook-ceph.enable = true;

      descheduler.enable = true;
      reloader.enable = true;
      external-secrets.enable = true;
      external-secrets.bitwarden.organization_id = "ce96e43f-f2ce-4cd7-a36f-b30e0149eeaf";
      external-secrets.bitwarden.project_id = "baf88382-abda-41b2-8d0f-b30e014c2db9";
      crossplane.enable = true;

      prometheus.enable = true;
      alertmanager.enable = true;
      node-exporter.enable = true;
      kube-state-metrics.enable = true;
      grafana.enable = true;
      loki.enable = true;
      gatus.enable = true;

      keycloak.enable = true;
      keycloak.crossplane.enable = true;
      oauth2-proxy.enable = true;
      oauth2-proxy.provider = "keycloak";
      vaultwarden.enable = true;

      jellyfin.enable = true;
      maintainerr.enable = true;
      qbittorrent.enable = true;
      autobrr.enable = true;
      bazarr.enable = true;
      radarr.enable = true;
      sonarr.enable = true;
      lidarr.enable = true;
      readarr.enable = true;
      readarr.rreading-glasses.enable = true;
      prowlarr.enable = true;
      recyclarr.enable = true;

      excalidraw.enable = true;

      #   clickhouse.enable = true;
      #   windmill.enable = true;
      #   jitsi.enable = true;
      #   immich.enable = true;
    };
  };
}
