{
  config,
  inputs,
  lib,
  ...
}: let
  inherit (lib) flip mapAttrsToList fileContents mkForce mkMerge;
  inherit (config.canivete.people) me;
  buildMachines = flip mapAttrsToList config.canivete.deploy.nixos.nodes (name: machine: {
    hostName = name;
    protocol = "ssh-ng";
    sshUser = me;
    inherit (machine) system;
    maxJobs = 10;
    speedFactor = 1000;
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
  canivete.deploy = {
    system.homeModules.nix = {pkgs, ...}: {
      nix = {
        inherit (common) extraOptions;
        # Some conflict from home-manager managing itself, but it must be specified
        package = mkForce pkgs.nixVersions.latest;
      };
    };
    system.modules.nix = {pkgs, ...}: {nix.package = pkgs.nixVersions.latest;};
    nixos.modules.nix.nix = mkMerge [
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
    darwin.modules.nix.nix = mkMerge [
      common
      {
        configureBuildUsers = true;
        useDaemon = true;
        linux-builder.enable = true;
        linux-builder.systems = ["aarch64-linux"];
        linux-builder.maxJobs = 4;
      }
    ];
    droid.modules.nix.nix.extraOptions = common.extraOptions;
  };
}
