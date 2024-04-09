flake @ {
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
  perSystem.canivete.opentofu = {
    plugins = ["integrations/github" "gitlabhq/gitlab" "cloudflare/cloudflare"];
    sharedModules = {
      github.provider.github.token = "\${ data.external.sops_decrypt.result[\"github_pat\"] }";
      github.resource.github_user_ssh_key = pipe config.people.users [
        (filterAttrs (_: hasAttrByPath ["accounts" "github"]))
        (mapAttrs (name: _: {
          title = "dotfiles";
          key = readFile (./dev/sops + "/${name}.pub");
        }))
      ];
      gitlab.provider.gitlab.token = "\${ data.external.sops_decrypt.result[\"gitlab_pat\"] }";
      gitlab.resource.gitlab_user_sshkey = pipe config.people.users [
        (filterAttrs (_: hasAttrByPath ["accounts" "gitlab"]))
        (mapAttrs (name: _: {
          title = "dotfiles";
          key = readFile (./dev/sops + "/${name}.pub");
        }))
      ];
      cloudflare.provider.cloudflare.api_token = "\${ data.external.sops_decrypt.result[\"cloudflare_pat\"] }";
      # TODO prevent this account name hardcoding
      cloudflare.data.cloudflare_accounts.main.name = "Tristanschrader@proton.me's Account";
      cloudflare.resource = {
        cloudflare_zone.trdos = {
          account_id = "\${ data.cloudflare_accounts.main.accounts[0].id }";
          zone = "trdos.me";
        };
        cloudflare_record.base = {
          name = "@";
          value = "157.131.152.251";
          type = "A";
          zone_id = "\${ cloudflare_zone.trdos.id }";
        };
      };
    };
  };
  flake.homeModules.ssh = {
    config,
    pkgs,
    ...
  }: let
    user = config.home.username;
    home = config.home.homeDirectory;
  in
    mkMerge [
      {
        programs.ssh.enable = true;
        programs.ssh.forwardAgent = true;
        programs.ssh.matchBlocks = mapAttrs (_: getAttr "ssh") flake.config.nixos;
        sops.secrets.ssh = {
          format = "binary";
          sopsFile = ./dev/sops + "/${user}";
        };
        # TODO still not working
        # home.file.".ssh/${user}".source = home.config.sops.secrets.ssh.path;
        home.file.".ssh/${user}.pub".source = ./dev/sops + "/${user}.pub";
      }
      (mkIf pkgs.stdenv.isLinux {
        services.ssh-agent.enable = true;
      })
    ];
}
