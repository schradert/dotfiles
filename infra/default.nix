{
  config,
  inputs,
  lib,
  ...
}: {
  # FIXME why is k3s CRASHING?! overloading it with deployment requests at the beginning?
  # FIXME why is nixos_sirver_system failing initial deployment? i have to run twice
  # TODO how should I integrate this
  # TODO get headscale_api_key to wait for node installation to be reachable
  # TODO why is kubernetes in opentofu showing up sensitive
  # TODO why does openebs-localpv-provisioner fail?
  # NOTE /builds + /modules are just temporary out of store symlinks
  flake.dotfiles = lib.mapAttrs (_: lib.getAttr "dotfiles") config.allSystems;
  flake.overlays.nur = inputs.nur.overlays.default;
  perSystem = {
    config,
    pkgs,
    system,
    ...
  }: let
    inherit (lib) getExe mkForce;
    deploy = "nix run .#canivete.${system}.opentofu.script -- --workspace deploy";
  in {
    apps.deploy.program = pkgs.writeShellScriptBin "deploy" "${deploy} \"$@\"";
    apps.deploy-all.program = pkgs.writeShellScriptBin "deploy-all" ''
      set -euo pipefail
      ${deploy} -auto-approve -target shell_script.headscale_api_key
      ${deploy} -auto-approve
    '';
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
        lychee.toml.exclude = ["file://*"];
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
  dotfiles = {canivete, ...}: {
    domain = "trdos.me";
    me = "tristan";
    people.tristan = "tristan";

    clouds.hetzner.enable = true;

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
    kubenix.kubernetes.resources.namespaces = {
      # TODO define all namespaces (dynamically?!)
      cicd = {};
      monitoring = {};
      security = {};
      storage = {};
    };

    services = {
    #   cert-manager.enable = true;
    #   cert-manager.provider.cloudflare.token = canivete.vals.sops.default "cloudflare/token";
      cilium.enable = true;
      coredns.enable = true;
    #   descheduler.enable = true;
    #   external-dns.enable = true;
    #   external-secrets.enable = true;
    #   gatus.enable = true;
    #   kubelet-csr-approver.enable = true;
    #   oauth2-proxy.enable = true;
    #   nginx.enable = true;
    #   openebs.enable = true;
    #   prometheus.enable = true;
    #   reloader.enable = true;
    #   snapshot-controller.enable = true;
    #   spegel.enable = true;
    #   volsync.enable = true;

    #   postgres.enable = true;
    #   grafana.enable = true;
    #   clickhouse.enable = true;
    #   windmill.enable = true;

    #   jitsi.enable = true;
    #   immich.enable = true;
    #   excalidraw.enable = true;
    #   excalidraw.release.values.ingress = {
    #     annotations = [];
    #     className = "";
    #   };
    #   # TODO add all of the services
    #   # TODO decouple services
    };
  };
}
