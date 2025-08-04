{
  dotfiles.nixos = {
    config,
    flake,
    lib,
    perSystem,
    ...
  }: let
    inherit (flake.config.canivete.meta.people) users;
    inherit (lib) mapAttrs' mkDefault mkForce mkOption nameValuePair types;
  in {
    nixpkgs.overlays = [flake.inputs.nur.overlays.default];
    home-manager.backupFileExtension = "bak";
    home-manager.sharedModules = [
      ({config, ...}: {
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
        fonts.fontconfig.enable = true;
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
        home.stateVersion = mkDefault "25.11";
        programs = {
          bat.enable = true;
          dircolors.enable = true;
          eza.enable = true;
          fd.enable = true;
          fzf.enable = true;
          helix.enable = true;
          helix.package = perSystem.inputs'.helix.packages.default;
          home-manager.enable = true;
          ripgrep.enable = true;
          ssh.enable = true;
          vim.enable = true;
          yazi.enable = true;
          zoxide.enable = true;
        };
      })
      {
        # JQ
        programs = {
          jq.enable = true;
          jqp.enable = true;
          doom-emacs.extraPackages = e: [e.jq-mode];
          doom-emacs.tangle.config = ''
            (use-package! jq-mode
              :init
              (autoload 'jq-mode "jq-mode.el" "Major mode for editing jq files" t)
              (add-to-list 'auto-mode-alist '("\\.jq$" . jq-mode))

              :config
              (after! json-mode
                (map! :map json-mode-map
                      "C-c C-j" #'jq-interactively))
              (setq jq-interactive-command "yq"
                    jq-interactive-font-lock-mode #'yaml-mode
                    jq-interactive-default-options "--yaml-roundtrip"))
          '';
        };
      }
    ];
    home-manager.useGlobalPkgs = true;
    # Can be quite large...
    systemd.services =
      mapAttrs'
      (username: _: nameValuePair "home-manager-${username}" {serviceConfig.TimeoutStartSec = mkForce "10m";})
      flake.config.canivete.meta.people.users;
  };
}
