flake @ {
  config,
  inputs,
  nix,
  ...
}:
with nix; let
  inherit (config.canivete.people) me users;
  sshFile = name: inputs.self + "/.canivete/sops/${name}";
  linkSecrets = system: let
    inherit (system.pkgs.stdenv) isDarwin;
    configDirectory = if isDarwin then "Library/Application Support" else ".config";
    users = system.config.home-manager.users or (
      let node = config.canivete.deploy.darwin.nodes.${system.config.networking.hostName};
      in mapAttrs (name: _: node.profiles.${name}.raw.config) node.home
    );
    commands = pipe users [
      (mapAttrsToList (_: home: with home.home; "_install \"${username}\" \"data.external.ssh-key-${username}\" \"${homeDirectory}/.ssh/${username}\""))
      (with users.${me}.home; concat ["_install \"${username}\" \"data.external.age-me\" \"${homeDirectory}/${configDirectory}/sops/age/keys.txt\""])
      (concatStringsSep "\n")
    ];
  in system.pkgs.writeShellApplication {
    name = "link-secrets";
    runtimeInputs = optional (!isDarwin) system.pkgs.sudo;
    text = ''
      _install() {
          local username="$1"
          local secret="/private/canivete/secrets/$2"
          local symlink="$3"
          chown "$username" "$secret"
          sudo -u "$username" mkdir -p "$(dirname "$symlink")"
          sudo -u "$username" ln -sf "$secret" "$symlink"
      }
      ${commands}
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
      (flip mapAttrs' users (name: _: nameValuePair "data.external.ssh-key-${name}" "result.contents" ))
      {"data.external.age-me" = "result.contents";}
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
    darwin.modules.ssh = darwin @ {pkgs, ...}: {
      launchd.agents.secrets = {
        command = getExe (linkSecrets darwin);
        serviceConfig.RunAtLoad = true;
      };
    };
    nixos.homeModules.ssh.services.ssh-agent.enable = true;
    nixos.modules.ssh = nixos @ {config, pkgs, ...}: {
      home-manager.sharedModules = toList {dotfiles.hostname = config.networking.hostName;};
      services.openssh.enable = true;
      security.pam.sshAgentAuth.enable = true;
      security.polkit.enable = true;
      users.users = mkMerge [
        (flip mapAttrs users (name: _: {openssh.authorizedKeys.keyFiles = [(sshFile "${name}.pub")];}))
        {root.openssh.authorizedKeys.keyFiles = config.users.users.${me}.openssh.authorizedKeys.keyFiles;}
      ];
      systemd.services.secrets = {
        script = getExe (linkSecrets nixos);
        wantedBy = ["multi-user.target"];
      };
    };
  };
}
