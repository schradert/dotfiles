{config, nix, ...}: with nix; let
  option = mkOption {
    type = str;
    description = mdDoc "The hostname of the relevant machine";
    example = "another-server";
  };
in {
  flake.nixosModules.hostname = {config, ...}: {
    options.dotfiles.hostname = option;
    config.networking.hostName = config.dotfiles.hostname;
  };
  flake.homeModules.hostname.options.dotfiles.hostname = option;
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
  flake.homeModules.ssh = home: let
    user = home.config.home.username;
  in {
    programs.ssh.enable = true;
    programs.ssh.forwardAgent = true;
    sops.secrets.ssh = {
      format = "binary";
      sopsFile = ./dev/sops + "/${user}";
    };
    # TODO still not working
    # home.file.".ssh/${user}".source = home.config.sops.secrets.ssh.path;
    home.file.".ssh/${user}.pub".source = ./dev/sops + "/${user}.pub";
  };
}
