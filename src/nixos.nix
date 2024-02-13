{
  config,
  inputs,
  nix,
  withSystem,
  ...
}:
with nix; {
  options.nixos = mkOption {
    type = attrsOf (submodule {
      options.system = mkSystemOption {};
      options.module = mkOpenModuleOption {};
    });
    default = {};
    description = "Specific NixOS configurations";
  };
  config.flake.nixosModules.default = {pkgs, ...}: let
    me = config.people.me;
    my = config.people.my;
    keys = nix.catAttrs "public" (attrValues my.sshKeys);
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
    time.timeZone = "America/Los_Angeles";
    users.mutableUsers = true;
    users.users.${me} = {
      isNormalUser = true;
      home = "/home/${me}";
      description = my.name;
      extraGroups = ["wheel" "tty" "networkmanager"];
      shell = pkgs.zsh;
      openssh.authorizedKeys.keys = keys;
    };
    users.users.root.openssh.authorizedKeys.keys = keys;
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
          home-manager.users.${config.people.me} = {
            imports = attrValues inputs.self.homeModules;
            options.dotfiles = nixos.options.dotfiles;
            config.dotfiles = nixos.config.dotfiles;
          };
          nixpkgs.hostPlatform = system;
          dotfiles.hostname = mkDefault name;
        });
      }))
  config.nixos;
}
