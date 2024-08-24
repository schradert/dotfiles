flake @ {
  config,
  inputs,
  nix,
  ...
}:
with nix; let
  inherit (config.canivete.people) me users;
  sshFile = name: inputs.self + "/.canivete/sops/${name}";
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
          owner = "${name}:root";
        }))
      {
        "data.external.age-me" = {
          attr = "result.contents";
          owner = "${me}:root";
        };
      }
    ];
    system.homeModules.ssh = {
      config,
      lib,
      pkgs,
      ...
    }: let
      inherit (config.home) username homeDirectory;
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
                  extraOptions.StrictHostKeyChecking = "accept-new";
                })
              ]
          ))
        ];
        home.file.".ssh/${username}.pub".source = sshFile "${username}.pub";
        home.activation.sshKeyLinking = lib.hm.dag.entryAfter ["writeBoundary"] "cp -f /canivete/secrets/data.external.ssh-key-${username} ${homeDirectory}/.ssh/${username}";
        home.activation.ageKeyLinking = let
          agePath = let
            directoryConfig =
              if pkgs.stdenv.isDarwin
              then "Library/Application Support"
              else ".config";
          in "~/${directoryConfig}/sops/age/keys.txt";
        in
          mkIf (username == me) (lib.hm.dag.entryAfter ["writeBoundary"] "cp -f /canivete/secrets/data.external.age-me ${agePath}");
      };
    };
    nixos.homeModules.ssh.services.ssh-agent.enable = true;
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
