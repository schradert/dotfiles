{
  config,
  inputs,
  ...
}: let
  inherit (config.canivete.deploy) nodes;
in {
  flake.overlays.nix-inspect = _: prev: {nix-inspect = inputs.nix-inspect.packages.${prev.system}.default;};
  dotfiles = {
    config,
    lib,
    ...
  }: let
    inherit (config) me;
    inherit (lib) flip mapAttrsToList fileContents mkForce mkMerge;
    buildMachines = flip mapAttrsToList nodes (name: node: {
      hostName = name;
      protocol = "ssh-ng";
      sshUser = me;
      inherit (node.canivete) system;
      maxJobs = 10;
      speedFactor = 1000;
      # TODO how should I change these features for different systems?
      supportedFeatures = ["nixos-test" "benchmark" "big-parallel" "kvm"];
      mandatoryFeatures = [];
    });
    common = {
      inherit buildMachines;
      distributedBuilds = true;
      extraOptions = ''
        builders-use-substitutes = true
        experimental-features = nix-command flakes auto-allocate-uids
        keep-outputs = true
        keep-derivations = true
        trusted-users = ${me}
        warn-dirty = false
        use-xdg-base-directories = true
      '';
      optimise.automatic = true;
    };
    key = fileContents (inputs.self + "/.canivete/sops/${me}.pub");
  in {
    shared = {pkgs, ...}: {nix.package = pkgs.nixVersions.latest;};
    home-manager = {pkgs, ...}: {
      home.packages = with pkgs; [
        nix-btm
        nix-inspect
        nix-fast-build
        nix-output-monitor
      ];
      nix = {
        inherit (common) extraOptions;
        # Some conflict from home-manager managing itself, but it must be specified
        package = mkForce pkgs.nixVersions.latest;
      };
      # TODO why is it panicking when I try to call it from `nix run`?
      # programs.nix-your-shell.enable = true;
    };
    nixos.nix = mkMerge [
      common
      {
        settings.trusted-users = ["nix-ssh"];
        sshServe = {
          enable = true;
          write = true;
          protocol = "ssh-ng";
          keys = [key];
        };
      }
    ];
    darwin.nix = mkMerge [
      common
      {
        configureBuildUsers = true;
        useDaemon = true;
        linux-builder.enable = true;
        linux-builder.systems = ["aarch64-linux"];
        linux-builder.maxJobs = 4;
      }
    ];
    droid.nix = {inherit (common) extraOptions;};
  };
}
