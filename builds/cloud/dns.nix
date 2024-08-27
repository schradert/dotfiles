{
  config,
  nix,
  ...
}: let
  inherit (config.dotfiles) domain;
  inherit (config.canivete.people.my.profiles.default) email;
in {
  perSystem.canivete.opentofu.workspaces.deploy = {
    plugins = ["cloudflare/cloudflare"];
    modules.dns = {
      provider.cloudflare.api_token = nix.vals.sops "default.yaml#/cloudflare/pat";
      # TODO prevent this account name hardcoding
      data.cloudflare_accounts.main.name = email;
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
