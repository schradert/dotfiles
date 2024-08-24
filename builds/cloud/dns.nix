{
  config,
  nix,
  ...
}: {
  perSystem.canivete.opentofu.workspaces.deploy = {
    plugins = ["cloudflare/cloudflare"];
    modules.dns = {
      provider.cloudflare.api_token = nix.vals.sops "default.yaml#/cloudflare_pat";
      # TODO prevent this account name hardcoding
      data.cloudflare_accounts.main.name = "Tristanschrader@proton.me's Account";
      resource = {
        cloudflare_zone.trdos = {
          account_id = "\${ data.cloudflare_accounts.main.accounts[0].id }";
          zone = config.dotfiles.domain;
        };
        cloudflare_record.base = {
          name = "@";
          value = nix.vals.sops "default.yaml#/trdos_ip";
          type = "A";
          zone_id = "\${ cloudflare_zone.trdos.id }";
        };
        cloudflare_record.www = {
          name = "www";
          value = "\${ cloudflare_zone.trdos.zone }";
          type = "CNAME";
          zone_id = "\${ cloudflare_zone.trdos.id }";
        };
        cloudflare_record.wildcard = {
          name = "*";
          value = nix.vals.sops "default.yaml#/trdos_ip";
          type = "A";
          zone_id = "\${ cloudflare_zone.trdos.id }";
        };
      };
    };
  };
}
