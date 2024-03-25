{
  config,
  nix,
  ...
}:
with nix; {
  flake.homeModules.hostname.options.dotfiles.hostname = mkOption {
    type = str;
    description = mdDoc "The hostname of the relevant machine";
    example = "another-server";
  };
  flake.terranixModules.github = {
    terraform.required_providers.github = {
      source = "integrations/github";
      version = "6.0.0-rc2";
    };
    provider.github.token = "\${ data.external.sops_decrypt.result[\"github_pat\"] }";
    resource.github_user_ssh_key = pipe config.people.users [
      (filterAttrs (_: hasAttrByPath ["accounts" "github"]))
      (mapAttrs (name: _: {
        title = "dotfiles";
        key = readFile (./dev/sops + "/${name}.pub");
      }))
    ];
  };
  flake.terranixModules.gitlab = {
    terraform.required_providers.gitlab = {
      source = "gitlabhq/gitlab";
      version = "16.8.1";
    };
    provider.gitlab.token = "\${ data.external.sops_decrypt.result[\"gitlab_pat\"] }";
    resource.gitlab_user_sshkey = pipe config.people.users [
      (filterAttrs (_: hasAttrByPath ["accounts" "gitlab"]))
      (mapAttrs (name: _: {
        title = "dotfiles";
        key = readFile (./dev/sops + "/${name}.pub");
      }))
    ];
  };
  flake.homeModules.ssh = {
    config,
    lib,
    pkgs,
    ...
  }: let
    user = config.home.username;
  in
    lib.mkMerge [
      {
        programs.ssh.enable = true;
        programs.ssh.forwardAgent = true;
        sops.secrets.ssh = {
          format = "binary";
          sopsFile = ./dev/sops + "/${user}";
        };
        # TODO still not working
        # home.file.".ssh/${user}".source = home.config.sops.secrets.ssh.path;
        home.file.".ssh/${user}.pub".source = ./dev/sops + "/${user}.pub";
      }
      (lib.mkIf pkgs.stdenv.isLinux {
        services.ssh-agent.enable = true;
      })
    ];
}
