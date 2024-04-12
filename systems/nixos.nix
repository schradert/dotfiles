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
        system = mkSystemOption {default = head (import inputs.systems-default);};
        ssh = {
          hostname = mkOption {
            type = str;
            default = name;
            description = mdDoc "Identifier of machine";
          };
          user = mkOption {
            type = str;
            default = config.people.me;
            description = mdDoc "User to connect to host as";
          };
          identityFile = mkOption {
            type = str;
            default = "~/.ssh/${config.people.me}";
            description = mdDoc "SSH private key";
          };
          proxyJump = mkOption {
            type = str;
            default = config.domain;
            description = mdDoc "Relay server for SSH jump connection";
          };
        };
        module = mkOption {type = deferredModule;};
      };
    }));
    default = {};
    description = "Specific NixOS configurations";
  };
  config.perSystem.canivete.opentofu = {
    # TODO why do I have to specify hashicorp ones too? and if I only do hashicorp, it wants opentofu??
    workspaces.nixos.plugins = ["opentofu/null" "opentofu/external" "hashicorp/null" "hashicorp/external"];
    workspaces.nixos.modules.default =  {pkgs, ...}: {
      config = let
        mkModule = hostname: _: let
          nixFlags = "--extra-experimental-features \"nix-command flakes\"";
          drv = "\${ data.external.nixos_eval_${hostname}.result.drv }";
          systemdFlags = [
            "--collect"
            "--no-ask-password"
            "--pipe"
            "--quiet"
            "--same-dir"
            "--wait"
            "--setenv"
            "LOCALE_ARCHIVE"
            "--setenv"
            "NIXOS_INSTALL_BOOTLOADER="
            "--service-type"
            "exec"
            "--unit"
            # Using the full 'nixos-rebuild-switch-to-configuration' name on sirver would fail to collect/cleanup
            "nixos-switch"
          ];
        in {
          data.external."nixos_eval_${hostname}".program = pkgs.execBash ''
            nix ${nixFlags} path-info --derivation ${inputs.self}#nixosConfigurations.${hostname}.config.system.build.toplevel | \
                ${pkgs.jq}/bin/jq --raw-input '{"drv":.}'
          '';
          resource.null_resource."nixos_switch_${hostname}" = {
            triggers.drv = drv;
            # TODO does NIX_SSHOPTS serve a purpose outside of nixos-rebuild
            provisioner.local-exec.command = ''
              set -x
              sshFlags="-o ControlMaster=auto -o ControlPath=/tmp/%C -o ControlPersist=60 -o StrictHostKeyChecking=accept-new"
              export NIX_SSHOPTS="$sshFlags"
              nix ${nixFlags} copy --derivation --to ssh://${config.root} ${drv}
              closure=$(ssh $sshFlags ${config.root} nix-store --verbose --realise ${drv})
              nix ${nixFlags} copy --from ssh://${config.root} --to ssh://${hostname} "$closure"
              ssh $sshFlags ${hostname} sudo nix-env --profile /nix/var/nix/profiles/system --set "$closure"
              ssh $sshFlags ${hostname} sudo systemd-run ${concatStringsSep " " systemdFlags} "$closure/bin/switch-to-configuration" switch
            '';
          };
        };
      in
        mkMerge (mapAttrsToList mkModule config.nixos);
    };
  };
  config.flake.nixosModules.default = {pkgs, ...}: let
    inherit (config.people) me my;
    keys = [(inputs.self + "/dev/sops/${me}.pub")];
  in {
    environment.pathsToLink = ["/share/zsh"];
    environment.shells = [pkgs.zsh];
    i18n.defaultLocale = "en_US.UTF-8";
    programs.zsh.enable = true;
    services.openssh.enable = true;
    security.polkit.enable = true;
    security.pam.sshAgentAuth.enable = true;
    security.pam.sshAgentAuth.authorizedKeysFiles = mkForce ["/etc/ssh/authorized_keys.d/%u"];
    security.sudo.extraRules = toList {
      users = [me];
      commands = toList {
        command = "ALL";
        options = ["NOPASSWD"];
      };
    };
    system.stateVersion = "22.11";
    system.autoUpgrade = {
      enable = true;
      allowReboot = true;
      flake = "github:schradert/dotfiles";
      persistent = true;
      rebootWindow.lower = "05:00";
      rebootWindow.upper = "06:00";
    };
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
        specialArgs = inputs.self.nixos-flake.lib.specialArgsFor.nixos // {inherit nix;};
        modules = toList (nixos: {
          imports = attrValues inputs.self.systemModules ++ attrValues inputs.self.nixosModules ++ [cfg.module];
          systemd.services."home-manager-${config.people.me}".serviceConfig.TimeoutStartSec = mkForce "10m";
          home-manager.extraSpecialArgs = inputs.self.nixos-flake.lib.specialArgsFor.common // {inherit nix;};
          home-manager.users.${config.people.me} = {
            imports = attrValues inputs.self.homeModules;
            options.dotfiles = nixos.options.dotfiles;
            config.dotfiles =
              nixos.config.dotfiles
              // {
                hostname = name;
              };
          };
          nix.settings.trusted-users = [config.people.me];
          nixpkgs.hostPlatform = system;
          networking.hostName = name;
        });
      }))
  config.nixos;
}
