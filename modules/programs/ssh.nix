flake @ {
  config,
  inputs,
  nix,
  ...
}:
with nix; let
  inherit (config.canivete.people) me users;
  sshFile = name: inputs.self + "/.canivete/sops/${name}";
  linkSecrets = home: let
    inherit (home.config.home) username homeDirectory;
    directoryConfig =
      if home.pkgs.stdenv.isDarwin
      then "Library/Application Support"
      else ".config";
    agePath = "${homeDirectory}/${directoryConfig}/sops/age/keys.txt";
  in home.pkgs.writeShellApplication {
    name = "link-secrets";
    text = ''
      ln -sf "/canivete/secrets/data.external.ssh-key-${username}" "${homeDirectory}/.ssh/${username}"
      mkdir -p "${dirOf agePath}"
      ln -sf /canivete/secrets/data.external.age-me "${agePath}"
    '';
  };
in {
  perSystem = {pkgs, ...}: {
    canivete.opentofu.workspaces.deploy.modules.ssh-key.data.external = let
      decrypt = file:
        pkgs.execBash ''
          ${getExe pkgs.sops} --decrypt ${sshFile file} | \
            ${getExe pkgs.jq} --null-input --rawfile contents /dev/stdin '{"contents":$contents}'
        '';
    in
      mkMerge [
        (flip mapAttrs' users (name: _: nameValuePair "ssh-key-${name}" {program = decrypt name;}))
        {age-me.program = decrypt "${me}.txt";}
      ];
  };
  canivete.deploy = {
    system.modules.ssh.canivete.secrets = mkMerge [
      (flip mapAttrs' users (name: _:
        nameValuePair "data.external.ssh-key-${name}" {
          attr = "result.contents";
          owner = "${name}:${name}";
        }))
      {
        "data.external.age-me" = {
          attr = "result.contents";
          owner = "${me}:${me}";
        };
      }
    ];
    system.homeModules.ssh = home @ {
      config,
      lib,
      pkgs,
      ...
    }: let
      inherit (config.home) username;
    in {
      options.dotfiles.hostname = mkOption {
        type = str;
        description = "The hostname of the relevant machine";
        example = "another-server";
      };
      config = {
        home.file.".ssh/${username}.pub".source = sshFile "${username}.pub";
        programs.ssh = {
          enable = true;
          forwardAgent = true;
          addKeysToAgent = "yes";
          matchBlocks = pipe flake.config.canivete.deploy [
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
                    extraOptions.StrictHostKeyChecking = "accept-new";
                  })
                ]
            ))
          ];
        };
      };
    };
    nixos.homeModules.ssh = home @ {pkgs, ...}: {
      services.ssh-agent.enable = true;
      systemd.user.services.secrets = {
        Install.WantedBy = ["default.target"];
        Service.RemainAfterExit = "yes";
        Service.Type = "oneshot";
        Service.ExecStart = getExe (linkSecrets home);
      };
    };
    darwin.homeModules.ssh = home @ {pkgs, ...}: {
      launchd.agents.secrets = {
        enable = true;
        config.RunAtLoad = true;
        config.Program = getExe (linkSecrets home);
      };
    };
    nixos.modules.ssh = {config, ...}: {
      home-manager.sharedModules = toList {dotfiles.hostname = config.networking.hostName;};
      services.openssh.enable = true;
      security.pam.sshAgentAuth.enable = true;
      security.polkit.enable = true;
      users.users = mkMerge [
        (flip mapAttrs users (name: _: {openssh.authorizedKeys.keyFiles = [(sshFile "${name}.pub")];}))
        {root.openssh.authorizedKeys.keyFiles = config.users.users.${me}.openssh.authorizedKeys.keyFiles;}
      ];
    };
  };
}
