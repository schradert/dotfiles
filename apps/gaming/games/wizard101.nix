let
  controls = {
    controller_mappings = {
      version = "3";
      revision = "1";
      title = "#Title";
      description = "#SettingsController_AutosaveDescription";
      export_type = "unknown";
      controller_type = "controller_neptune";
      controller_caps = "23117823";
      major_revision = "0";
      minor_revision = "0";
      Timestamp = "0";
      localization.english.title = "Wizard 101";
      group = [
        {
          id = "0";
          mode = "four_buttons";
          name = "";
          description = "";
          inputs = {
            button_a.activators.Full_Press = {
              bindings.binding = ["key_press SPACE, , "];
              settings.repeat_rate = "99";
            };
            button_b.activators.Full_Press = {
              bindings.binding = ["key_press E, , "];
              settings.repeat_rate = "99";
            };
            button_x.activators.Full_Press = {
              bindings.binding = ["key_press X, , "];
              settings.repeat_rate = "99";
            };
          };
          settings.button_size = "17994";
          settings.button_dist = "19994";
        }
        {
          id = "1";
          mode = "mouse_region";
          name = "";
          description = "";
          inputs.click.activators.Soft_Press.bindings.binding = "mouse_button LEFT, , ";
          settings.output_joystick = "3";
          settings.position_x = "43";
        }
        {
          id = "2";
          mode = "dpad";
          name = "";
          description = "";
          inputs = {
            dpad_north.activators.Full_Press = {
              bindings.binding = ["key_press W, , "];
              settings.repeat_rate = "99";
              settings.haptic_intensity = "1";
            };
            dpad_south.activators.Full_Press = {
              bindings.binding = ["key_press S, , "];
              settings.repeat_rate = "99";
              settings.haptic_intensity = "1";
            };
            dpad_east.activators.Full_Press = {
              bindings.binding = ["key_press A, , "];
              settings.repeat_rate = "99";
              settings.haptic_intensity = "1";
            };
            dpad_west.activators.Full_Press = {
              bindings.binding = ["key_press D, , "];
              settings.repeat_rate = "99";
              settings.haptic_intensity = "1";
            };
            click.activators.Full_Press = {
              bindings.binding = ["key_press NUM_LOCK, , "];
              settings.repeat_rate = "99";
              settings.haptic_intensity = "1";
            };
          };
          settings.requires_click = "0";
          settings.edge_binding_radius = "24995";
        }
        {
          id = "3";
          mode = "switches";
          name = "";
          description = "";
          inputs = {
            button_escape.activators.Full_Press.bindings.binding = ["key_press Q, , "];
            button_menu.activators.Full_Press.bindings.binding = ["key_press M, , "];
            button_capture.activators.release.bindings.binding = ["controller_action system_key_1, , "];
          };
        }
        {
          id = "4";
          mode = "joystick_mouse";
          name = "";
          description = "";
          inputs.touch.activators.Full_Press.bindings.binding = ["mouse_button RIGHT, , "];
          settings.output_joystick = "2";
          settings.sensitivity_horiz_scale = "30";
          settings.sensitivity_vert_scale = "15";
        }
        {
          id = "5";
          mode = "scrollwheel";
          name = "";
          description = "";
          inputs = {
            scroll_wheel_list_0.activators.Full_Press.bindings.binding = ["key_press C, , "];
            scroll_wheel_list_1.activators.Full_Press.bindings.binding = ["key_press B, , "];
            scroll_wheel_list_3.activators.Full_Press.bindings.binding = ["key_press P, , "];
            scroll_wheel_list_4.activators.Full_Press.bindings.binding = ["key_press Q, , "];
            scroll_wheel_list_5.activators.Full_Press.bindings.binding = ["key_press M, , "];
            scroll_wheel_list_6.activators.Full_Press.bindings.binding = ["key_press J, , "];
          };
          settings.scroll_type = "2";
        }
      ];
      preset = [
        {
          id = "0";
          name = "Default";
          group_source_bindings = {
            "0" = "button_diamond active";
            "1" = "right_trackpad active";
            "2" = "joystick active";
            "3" = "switch active";
            "4" = "right_joystick active";
            "5" = "left_trackpad active";
          };
        }
      ];
      settings.left_trackpad_mode = "0";
      settings.right_trackpad_mode = "0";
    };
  };
in {
  dotfiles.home-manager = {
    config,
    lib,
    pkgs,
    ...
  }: {
    config = lib.mkIf config.dotfiles.profiles.gaming.enable {
      dotfiles.programs.steam.external.manual = {
        # TODO why are these invalid when fetched?
        # NOTE upstream is obscured with browser request IDs giving 403, so I am hosting a mirror
        "Wizard 101".shortcut.exe = pkgs.fetchurl {
          name = "InstallWizard101.exe";
          url = "https://drive.google.com/uc?id=1iVWSiEcGjwk_LKcp1937y4q3N3rt_JmQ";
          hash = "sha256-2ftofsBYx1PIeUvuBrieB3/AWJlvp36HtFd/xSk0jUs=";
          executable = true;
        };
        "Pirate 101".shortcut.exe = pkgs.fetchurl {
          name = "InstallPirate101.exe";
          url = "https://drive.google.com/uc?id=1Nk_WThZYfW5xJII7G-JiL2rATpU3mA3k";
          hash = "sha256-+9gnfENkaN1wMs5vAG1CNKxToyNpT5XWWTRtdL+oZFw=";
          executable = true;
        };
        home.activation.wizard101-controls = lib.hm.dag.entryAfter ["writeBoundary"] ''
          dest="$HOME/.steam/steam/steamapps/common/Steam Controller Configs/$(basename "$HOME"/.steam/steam/userdata/*)/config/wizard 101/controller_neptune.vdf"
          src=${(pkgs.formats.json {}).generate "wizard101.controls.json" controls}
          mkdir -p "$(dirname "$dest")"
          ${lib.getExe pkgs.json2vdf} > "$dest" < <(${lib.getExe pkgs.jq} ".controller_mappings += {url: \"autosave:$dest\"}" $src)
        '';
      };
    };
  };
}
