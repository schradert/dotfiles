{
  config,
  lib,
  ...
}: let
  inherit (config.canivete.meta.people) users;
  inherit (lib) attrNames mkOption types;
  inherit (types) enum str;
in {
  dotfiles.home-manager = {
    config,
    pkgs,
    ...
  }: let
    inherit (config.home) username;
  in {
    options.dotfiles.profile = mkOption {
      type = enum (attrNames users.${username}.profiles);
      example = "work";
      description = "The dotfiles profile to use for this configuration";
      default = "default";
    };
    options.dotfiles.editor = mkOption {
      type = str;
      default = "vim";
      example = "emacs";
      description = "Default editor to use for profile";
    };
    config.home.homeDirectory = "/${
      if pkgs.stdenv.isDarwin
      then "Users"
      else "home"
    }/${username}";
    config.home.sessionVariables = let
      inherit (config) xdg;
    in {
      XDG_CACHE_HOME = xdg.cacheHome;
      XDG_CONFIG_HOME = xdg.configHome;
      XDG_DATA_HOME = xdg.dataHome;
      XDG_STATE_HOME = xdg.stateHome;
      # TODO how can I get the user UID?
      XDG_RUNTIME_DIR = "/run/user/1000";
    };
    config.programs.home-manager.enable = true;
  };
}
