flake @ {
  canivete,
  config,
  inputs,
  lib,
  ...
}: let
  inherit (canivete) mkModuleOption;
  inherit (config.dotfiles) domain me nodes people root nixos darwin droid home-manager kubenix shared system;
  inherit (lib) mapAttrs mkEnableOption mkForce mkIf mkOption mkMerge types;
  inherit (types) attrsOf str submodule;
in {
  options.dotfiles = mkOption {
    default = {};
    description = "Project infrastructure";
    type = submodule ({config, ...}: {
      config._module.args = {inherit canivete;};
      options = {
        domain = mkOption {
          type = str;
          description = "Production deployment domain";
        };
        root = mkOption {
          type = str;
          description = "Production root server";
        };
        me = mkOption {
          type = str;
          description = "Production primary admin";
        };
        people = mkOption {
          type = attrsOf str;
          default = {};
          description = "Shorthand to email username";
        };
        nodes = mkOption {
          type = attrsOf (submodule {
            options.system = mkModuleOption {description = "Node system profile";};
          });
          default = {};
          description = "Nodes the cluster runs on";
        };
        nixos = mkModuleOption {description = "Common NixOS configuration for nodes";};
        shared = mkModuleOption {description = "Common profile configuration for nodes";};
        system = mkModuleOption {description = "Common system configuration for nodes";};
        darwin = mkModuleOption {description = "Common nix-darwin configuration for nodes";};
        droid = mkModuleOption {description = "Common nix-on-droid configuration for nodes";};
        home-manager = mkModuleOption {description = "Common home-manager configuration for nodes";};
      };
    });
  };
  config = {
    canivete.deploy = {
      sshUser = "root";
      # TODO why does this fail with "-oPermitLocalCommand: not found"?
      # sshOpts = ["StrictHostKeyChecking=accept-new"];
      canivete.modules = {inherit droid nixos darwin home-manager shared system;};
      nodes =
        mapAttrs (name: modules: {
          # FIXME this hostname seems wrong
          hostname = "${name}.vpn.${domain}";
          profiles.system.canivete.configuration = modules.system;
        })
        nodes;
    };
    canivete.meta = {
      inherit domain root;
      people = {
        inherit me;
        users =
          mapAttrs (_: username: {
            name = username;
            profiles.default.email = "${username}@${domain}";
          })
          people;
      };
    };
  };
}
