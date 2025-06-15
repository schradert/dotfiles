{
  canivete,
  config,
  inputs,
  lib,
  ...
}: let
  inherit (lib) flip pipe filterAttrs hasAttrByPath mapAttrs fileContents mkMerge;
  inherit (config.canivete) deploy meta;
  inherit (meta.people) me users;
  sshFile = name: inputs.self + "/.canivete/sops/${name}";
in {
  dotfiles = {
    home-manager = {
      config,
      pkgs,
      ...
    }: let
      inherit (config.home) homeDirectory username;
      inherit (pkgs.stdenv.hostPlatform) isDarwin isLinux;
    in {
      # TODO should I refresh any services?
      sops.secrets.ssh-private = {
        format = "binary";
        path = "${homeDirectory}/.ssh/${username}";
        sopsFile = sshFile username;
      };
      sops.secrets.ssh-age = {
        format = "binary";
        path = let
          configDirectory =
            if isDarwin
            then "Library/Application Support"
            else ".config";
        in "${homeDirectory}/${configDirectory}/sops/age/keys.txt";
        sopsFile = sshFile "${username}.txt";
      };
      home.file.".ssh/${username}.pub".source = sshFile "${username}.pub";
      services.ssh-agent.enable = isLinux;
      programs.ssh = {
        enable = true;
        forwardAgent = true;
        addKeysToAgent = "yes";
        matchBlocks = flip mapAttrs deploy.nodes (_: node: {
          inherit (node.config) hostname;
          user = username;
          identityFile = "${homeDirectory}/.ssh/${username}.pub";
          extraOptions.StrictHostKeyChecking = "accept-new";
          # TODO what other options? ControlMaster? ControlPath? ControlPersist?
        });
      };
    };
    nixos = {config, ...}: {
      services.openssh.enable = true;
      security.pam.rssh.enable = true;
      security.pam.sshAgentAuth.enable = true;
      security.polkit.enable = true;
      users.users = mkMerge [
        (flip mapAttrs users (name: _: {openssh.authorizedKeys.keyFiles = [(sshFile "${name}.pub")];}))
        {root.openssh.authorizedKeys.keyFiles = config.users.users.${me}.openssh.authorizedKeys.keyFiles;}
      ];
      # TODO is this sufficient for automated deployment?
      # TODO should I also do this for darwin?
      sops.secrets.root-ssh-private = {
        format = "binary";
        path = "/root/.ssh/root";
        sopsFile = sshFile me;
      };
    };
    opentofu.plugins = ["integrations/github" "gitlabhq/gitlab"];
    opentofu.modules = {
      provider.github.token = canivete.vals.sops "default.yaml#/github_pat";
      resource.github_user_ssh_key = pipe config.canivete.meta.people.users [
        (filterAttrs (_: hasAttrByPath ["accounts" "github"]))
        (mapAttrs (name: _: {
          title = "dotfiles";
          key = fileContents (inputs.self + "/.canivete/sops/${name}.pub");
        }))
      ];
      provider.gitlab.token = canivete.vals.sops "default.yaml#/gitlab_pat";
      resource.gitlab_user_sshkey = pipe config.canivete.meta.people.users [
        (filterAttrs (_: hasAttrByPath ["accounts" "gitlab"]))
        (mapAttrs (name: _: {
          title = "dotfiles";
          key = fileContents (inputs.self + "/.canivete/sops/${name}.pub");
        }))
      ];
    };
  };
}
