{
  config,
  nix,
  ...
}:
with nix; {
  options.flake = mkSubmoduleOptions {
    homeModules = mkModulesOption {
      description = "Home-Manager modules";
    };
  };
  config.flake.homeModules.home = home @ {pkgs, ...}: {
    options.dotfiles.editor = mkOption {
      type = enum ["vim" "emacs"];
      default = "vim";
      example = "emacs";
      description = "Default editor to use for profile";
    };
    options.dotfiles.profile = mkOption {
      type = enum (attrNames config.people.users.${home.config.home.username}.profiles);
      default = "default";
      example = "work";
      description = "The dotfiles profile to use for this configuration";
    };
    config = {
      home.username = config.people.me;
      home.homeDirectory = "/${
        if pkgs.stdenv.isDarwin
        then "Users"
        else "home"
      }/${config.people.me}";
      home.sessionPath = ["${home.config.home.homeDirectory}/.local/bin"];
      home.stateVersion = "23.05";
    };
  };
}
