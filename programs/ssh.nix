flake @ {
  config,
  inputs,
  nix,
  ...
}:
with nix; {
  flake.homeModules.hostname.options.dotfiles.hostname = mkOption {
    type = str;
    description = "The hostname of the relevant machine";
    example = "another-server";
  };
  perSystem.canivete.opentofu.workspaces.cloud = {
    plugins = ["integrations/github" "gitlabhq/gitlab" "cloudflare/cloudflare"];
    modules.default = {
      provider.github.token = "ref+sops://.canivete/sops/default.yaml#/github_pat";
      resource.github_user_ssh_key = pipe config.people.users [
        (filterAttrs (_: hasAttrByPath ["accounts" "github"]))
        (mapAttrs (name: _: {
          title = "dotfiles";
          key = readFile (inputs.self + "/.canivete/sops/${name}.pub");
        }))
      ];
      provider.gitlab.token = "ref+sops://.canivete/sops/default.yaml#/gitlab_pat";
      resource.gitlab_user_sshkey = pipe config.people.users [
        (filterAttrs (_: hasAttrByPath ["accounts" "gitlab"]))
        (mapAttrs (name: _: {
          title = "dotfiles";
          key = readFile (inputs.self + "/.canivete/sops/${name}.pub");
        }))
      ];
      provider.cloudflare.api_token = "ref+sops://.canivete/sops/default.yaml#/cloudflare_pat";
      # TODO prevent this account name hardcoding
      data.cloudflare_accounts.main.name = "Tristanschrader@proton.me's Account";
      resource = {
        cloudflare_zone.trdos = {
          account_id = "\${ data.cloudflare_accounts.main.accounts[0].id }";
          zone = config.domain;
        };
        cloudflare_record.base = {
          name = "@";
          value = "ref+sops://.canivete/sops/default.yaml#/trdos_ip";
          type = "A";
          zone_id = "\${ cloudflare_zone.trdos.id }";
        };
        cloudflare_record.www = {
          name = "www";
          value = "\${ cloudflare_zone.trdos.zone }";
          type = "CNAME";
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
          sopsFile = inputs.self + "/.canivete/sops/${user}";
        };
        # TODO still not working
        # home.file.".ssh/${user}".source = home.config.sops.secrets.ssh.path;
        home.file.".ssh/${user}.pub".source = inputs.self + "/.canivete/sops/${user}.pub";
      }
      (mkIf pkgs.stdenv.isLinux {
        services.ssh-agent.enable = true;
      })
    ];
}
