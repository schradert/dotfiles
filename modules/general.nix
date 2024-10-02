{config, lib, ...}: let
  inherit (config.canivete.people) users;
  inherit (lib) attrNames mkOption types;
  inherit (types) strMatching enum;
in {
  options.dotfiles.domain = mkOption {
    type = strMatching "^[a-z0-9\-]+\.[a-z]{2,}$";
    description = "Base domain for exposing nodes and services";
  };
  canivete.deploy.system.homeModules.general = {config, ...}: {
    options.dotfiles.profile = mkOption {
      type = enum (attrNames users.${config.home.username}.profiles);
      example = "work";
      description = "The dotfiles profile to use for this configuration";
      default = "default";
    };
    options.dotfiles.editor = mkOption {
      type = enum ["vim" "emacs"];
      default = "vim";
      example = "emacs";
      description = "Default editor to use for profile";
    };
  };
}
