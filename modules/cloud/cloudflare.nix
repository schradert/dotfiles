{canivete, config, lib, ...}: let
  inherit (config.canivete.meta.people.my.profiles.default) email;
in {
  perSystem = {pkgs, ...}: {
    config = lib.mkIf config.dotfiles.clouds.cloudflare.enable {
      canivete.devShells.shells.default.packages = [pkgs.cloudflare-cli];
    };
  };
  dotfiles = {config, ...}: {
    options.clouds.cloudflare.enable = lib.mkEnableOption "Cloudflare";
    config = lib.mkIf config.clouds.cloudflare.enable {
      opentofu.plugins = ["cloudflare/cloudflare/4.43.0"];
      opentofu.modules = {
        provider.cloudflare.api_token = canivete.vals.sops.default "cloudflare/pat";
        data.cloudflare_accounts.main.name = email;
      };
    };
  };
}