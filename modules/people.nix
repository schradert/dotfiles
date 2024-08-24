{
  config,
  nix,
  ...
}:
with nix; let
  inherit (config.canivete.people) users;
in {
  canivete.deploy.system.homeModules.auth = {config, ...}: {
    options.dotfiles.profile = mkOption {
      type = enum (attrNames users.${config.home.username}.profiles);
      example = "work";
      description = "The dotfiles profile to use for this configuration";
      default = "default";
    };
  };
}
