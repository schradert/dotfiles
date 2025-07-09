{
  canivete,
  config,
  lib,
  ...
}: let
  inherit (canivete) mkModuleOption;
  inherit (config.dotfiles) domain me nodes people nixos darwin droid home-manager shared system;
  inherit (lib) flip mapAttrs mkDefault mkForce mkOption types;
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
      nodes = flip mapAttrs nodes (name: modules: {
        hostname = "${name}.ssh.${domain}";
        profiles.system.canivete.configuration.imports = [
          modules.system
          {
            networking.domain = "ssh.${domain}";
            networking.hostName = mkForce name;
          }
        ];
      });
    };
    canivete.meta = {
      inherit domain;
      people = {
        inherit me;
        users =
          mapAttrs (_: username: {
            name = mkDefault username;
            profiles.default.email = mkDefault "${username}@${domain}";
          })
          people;
      };
    };
  };
}
