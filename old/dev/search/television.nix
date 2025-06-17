{inputs, ...}: {
  flake.overlays.television = _: prev: {television = inputs.television.packages.${prev.system}.default;};
  dotfiles.home-manager.programs.television = {
    enable = true;
    settings = {
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
}
