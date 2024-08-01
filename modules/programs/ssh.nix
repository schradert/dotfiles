flake @ {
  config,
  inputs,
  nix,
  ...
}:
with nix; let
  inherit (config.canivete.people) me users;
  sshFile = name: "${inputs.self}/.canivete/sops/${name}";
in {
  canivete.deploy = {
    system.homeModules.ssh = {config, ...}: let
      inherit (config.home) username;
    in {
      options.dotfiles.hostname = mkOption {
        type = str;
        description = "The hostname of the relevant machine";
        example = "another-server";
      };
      config = {
        programs.ssh.enable = true;
        programs.ssh.forwardAgent = true;
        programs.ssh.matchBlocks = pipe flake.config.canivete.deploy [
          # Attrset of all nodes (excluding "system")
          (flip removeAttrs ["system"])
          (mapAttrs (_: getAttr "nodes"))
          attrValues
          mergeAttrsList
          # Build SSH config block
          (mapAttrs (
            _: node: let
              inherit (node.target) host sshOptions;
            in
              pipe sshOptions [
                (map (flip pipe [
                  # Key-value pair from SSH option like ProxyJump=<url>
                  (match "^(.+)=(.+)$")
                  (evalWithAll nameValuePair)
                ]))
                listToAttrs
                # Exclude non-interactive options
                (flip removeAttrs ["ControlMaster" "ControlPath" "ControlPersist" "StrictHostKeyChecking"])
                # Home-manager defines these attributes in camelCase
                (mapAttrNames pascalToCamel)
                # Include sensible defaults
                (mergeAttrs {
                  hostname = host;
                  user = username;
                  identityFile = "~/.ssh/${username}";
                })
              ]
          ))
        ];
        sops.secrets.ssh = {
          format = "binary";
          sopsFile = sshFile username;
        };
        # TODO still not working
        # home.file.".ssh/${user}".source = home.config.sops.secrets.ssh.path;
        home.file.".ssh/${username}.pub".source = sshFile "${username}.pub";
      };
    };
    nixos.homeModules.ssh.services.ssh-agent.enable = true;
    nixos.modules.ssh = {config, ...}: {
      home-manager.sharedModules = toList {dotfiles.hostname = config.networking.hostName;};
      services.openssh.enable = true;
      security.pam.sshAgentAuth = {
        enable = true;
        authorizedKeysFiles = mkForce ["/etc/ssh/authorized_keys.d/%u"];
      };
      security.polkit.enable = true;
      users.users = mkMerge [
        (flip mapAttrs users (name: _: {
          openssh.authorizedKeys.keyFiles = [(sshFile "${name}.pub")];
        }))
        {
          root.openssh.authorizedKeys.keyFiles = config.users.users.${me}.openssh.authorizedKeys.keyFiles;
        }
      ];
    };
  };
}
