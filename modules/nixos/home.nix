{
  dotfiles.nixos = {
    config,
    flake,
    lib,
    options,
    ...
  }: let
    inherit (config.canivete.meta.people) users;
    inherit (lib) mapAttrs' mkForce mkOption nameValuePair types;
  in {
    home-manager.backupFileExtension = "bak";
    home-manager.sharedModules = [
      {
        options.dotfiles = options.dotfiles;
        config.dotfiles = config.dotfiles;
      }
      ({config, ...}: let
      in {
        options.dotfiles.profile = mkOption {
          type = types.enum (builtins.attrNames users.${config.home.username}.profiles);
          example = "work";
          description = "The dotfiles profile to use for this configuration";
          default = "default";
        };
        options.dotfiles.editor = mkOption {
          type = types.str;
          default = "vim";
          example = "emacs";
          description = "Default editor to use for profile";
        };
      })
      ({
        config,
        pkgs,
        ...
      }: {
        home.homeDirectory = "/${
          if pkgs.stdenv.isDarwin
          then "Users"
          else "home"
        }/${config.home.username}";
        home.sessionVariables = let
          inherit (config) xdg;
        in {
          XDG_CACHE_HOME = xdg.cacheHome;
          XDG_CONFIG_HOME = xdg.configHome;
          XDG_DATA_HOME = xdg.dataHome;
          XDG_STATE_HOME = xdg.stateHome;
          XDG_RUNTIME_DIR = "/run/user/1000";
        };
        home.stateVersion = "25.11";
        programs = {
          bat.enable = true;
          dircolors.enable = true;
          eza.enable = true;
          fzf.enable = true;
          home-manager.enable = true;
          jq.enable = true;
          jqp.enable = true;
          ssh.enable = true;
          vim.enable = true;
          yazi.enable = true;
          zellij.enable = true;
          zoxide.enable = true;
        };
      })
    ];
    home-manager.useGlobalPkgs = true;
    # Can be quite large...
    systemd.services =
      mapAttrs'
      (username: _: nameValuePair "home-manager-${username}" {serviceConfig.TimeoutStartSec = mkForce "10m";})
      flake.config.canivete.meta.people.users;
  };
}
