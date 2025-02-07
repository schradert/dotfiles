{inputs, ...}: {
  flake.overlays.television = _: prev: {television = inputs.television.packages.${prev.system}.default;};
  canivete.deploy.system.homeModules.television = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (config.dotfiles.programs) television;
    inherit (lib) mkEnableOption mkPackageOption mkIf mkOption;
    toml = pkgs.formats.toml {};
  in {
    options.dotfiles.programs.television = {
      enable = mkEnableOption "television fuzzy finder";
      package = mkPackageOption pkgs "television" {};
      config = mkOption {
        inherit (toml) type;
        default = {};
      };
      channels = mkOption {
        inherit (toml) type;
        default = {};
      };
    };
    config = mkIf television.enable {
      dotfiles.programs.television = {
        config = {
          ui.use_nerd_font_icons = true;
          previewers.file.theme = "Dracula";
          keybindings = {
            Channel = {
              quit = "ctrl-q";
              select_next_entry = "ctrl-j";
              select_prev_entry = "ctrl-k";
              select_next_page = "ctrl-shift-J";
              select_prev_page = "ctrl-shift-K";
              scroll_preview_half_page_down = "ctrl-l";
              scroll_preview_half_page_up = "ctrl-h";
              toggle_help = "ctrl-/";
            };
            RemoteControl = {
              quit = "ctrl-q";
              select_next_entry = "ctrl-j";
              select_prev_entry = "ctrl-k";
              select_next_page = "ctrl-shift-J";
              select_prev_page = "ctrl-shift-K";
              toggle_help = "ctrl-/";
            };
            SendToChannel = {
              quit = "ctrl-q";
              select_next_entry = "ctrl-j";
              select_prev_entry = "ctrl-k";
              select_next_page = "ctrl-shift-J";
              select_prev_page = "ctrl-shift-K";
              toggle_help = "ctrl-/";
            };
          };
        };
        channels = [
          {
            name = "Git Log";
            source_command = "git log --oneline --date=short --pretty=\"format:%h %s %an %cd\" \"$@\"";
            preview_command = "git show -p --stat --pretty=fuller --color=always {0}";
          }
          {
            name = "Dotfiles";
            source_command = "fd -t f . $HOME/.config";
            preview_command = "bat -n --color=always {0}";
          }
        ];
      };
      home.packages = [television.package];
      xdg.configFile."television/config.toml" = mkIf (television.config != {}) {source = toml.generate "television.config.toml" television.config;};
      xdg.configFile."television/channels.toml" = mkIf (television.channels != {}) {source = toml.generate "television.channels.toml" {cable_channels = television.channels;};};
    };
  };
}
