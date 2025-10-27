{
  canivete,
  config,
  lib,
  ...
}: let
  inherit (config.canivete.meta.people.my.profiles.default) email;
in {
  dotfiles = {config, pkgs, ...}: {
    options.clouds.cloudflare.enable = lib.mkEnableOption "Cloudflare";
    config = lib.mkIf config.clouds.cloudflare.enable {
      devenv.packages = [pkgs.cloudflare-cli];
      opentofu.plugins = ["cloudflare/cloudflare/5.6.0"];
      opentofu.modules = {
        provider.cloudflare.api_token = canivete.vals.sops.default "cloudflare";
        data.cloudflare_accounts.main.name = email;
      };
    };
  };
}
