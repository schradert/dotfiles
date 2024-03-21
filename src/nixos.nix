{
  config,
  inputs,
  nix,
  withSystem,
  ...
}:
with nix; {
  options.domain = mkOption {
    type = strMatching "^[a-z0-9\-]+\.[a-z]{2,}$";
    description = mdDoc "Base domain for NixOS nodes and services";
  };
  options.nixos = mkOption {
    type = attrsOf (submodule ({name, ...}: {
      options = {
        system = mkSystemOption {};
        ssh.hostname = mkOption {
          type = strMatching "^([a-z0-9\-]+\.){2,}[a-z]{2,}$";
          default = "${name}.nixos.${config.domain}";
          description = mdDoc "Unique DNS identifier of machine";
        };
        ssh.user = mkOption {
          type = str;
          default = config.people.me;
          description = mdDoc "User to connect to host as";
        };
        module = mkOption {type = attrsOf anything;};
      };
    }));
    default = {};
    description = "Specific NixOS configurations";
  };
  config.flake.nixosModules.default = {pkgs, ...}: let
    me = config.people.me;
    my = config.people.my;
    keys = [(./dev/sops + "/${me}.pub")];
  in {
    environment.pathsToLink = ["/share/zsh"];
    environment.shells = [pkgs.zsh];
    i18n.defaultLocale = "en_US.UTF-8";
    programs.zsh.enable = true;
    services.openssh.enable = true;
    security.polkit.enable = true;
    security.pam.enableSSHAgentAuth = true;
    security.sudo.extraRules = toList {
      users = [me];
      commands = toList {
        command = "ALL";
        options = ["NOPASSWD"];
      };
    };
    system.stateVersion = "22.11";
    system.autoUpgrade.enable = true;
    system.autoUpgrade.allowReboot = true;
    time.timeZone = "America/Los_Angeles";
    users.mutableUsers = true;
    users.users.${me} = {
      isNormalUser = true;
      home = "/home/${me}";
      description = my.name;
      extraGroups = ["wheel" "tty" "networkmanager"];
      shell = pkgs.zsh;
      openssh.authorizedKeys.keyFiles = keys;
    };
    users.users.root.openssh.authorizedKeys.keyFiles = keys;
    virtualisation.podman = {
      enable = true;
      dockerSocket.enable = true;
      defaultNetwork.settings.dns_enable = true;
    };
  };
  config.flake.nixosConfigurations = mapAttrs (name: cfg:
    withSystem cfg.system ({
      pkgs,
      system,
      ...
    }:
      inputs.nixpkgs.lib.nixosSystem {
        inherit pkgs system;
        specialArgs = inputs.self.nixos-flake.lib.specialArgsFor.nixos;
        modules = toList (nixos: {
          imports = attrValues inputs.self.systemModules ++ attrValues inputs.self.nixosModules ++ [cfg.module];
          systemd.services."home-manager-${config.people.me}".serviceConfig.TimeoutStartSec = mkForce "10m";
          home-manager.users.${config.people.me} = {
            imports = attrValues inputs.self.homeModules;
            options.dotfiles = nixos.options.dotfiles;
            config.dotfiles =
              nixos.config.dotfiles
              // {
                hostname = name;
              };
            config.programs.ssh.matchBlocks = pipe config.nixos [
              (removeAttrs' [name])
              (mapAttrs (_: node: {
                inherit (node.ssh) hostname user;
                identityFile = with config.people; "/home/${me}/.ssh/${me}";
              }))
            ];
          };
          nix.settings.trusted-users = [config.people.me];
          nixpkgs.hostPlatform = system;
          networking.hostName = name;
        });
      }))
  config.nixos;
}
