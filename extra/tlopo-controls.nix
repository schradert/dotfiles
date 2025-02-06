{
  controller_mappings = {
    version = "3";
    revision = "1";
    title = "#Title";
    # TODO maybe these need to be added back?
    # TODO are inactive groups actually necessary?!
    # creator = "";
    # progenitor = "";
    description = "#SettingsController_AutosaveDescription";
    export_type = "unknown";
    controller_type = "controller_neptune";
    controller_caps = "23117823";
    major_revision = "0";
    minor_revision = "0";
    Timestamp = "0";
    localization.english.title = "The Legend of Pirates Online";
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
          button_a.disabled_activators = {};
          button_b.activators.Full_Press = {
            bindings.binding = ["key_press ESCAPE, , "];
            settings.repeat_rate = "99";
          };
          button_b.disabled_activators = {};
          button_x.activators.Full_Press = {
            bindings.binding = ["mouse_button LEFT, , "];
            settings.repeat_rate = "99";
          };
          button_x.disabled_activators = {};
          button_y.activators.Full_Press = {
            bindings.binding = ["key_press T, , "];
            settings.repeat_rate = "99";
          };
          button_y.disabled_activators = {};
        };
        settings.button_size = "17994";
        settings.button_dist = "19994";
      }
      {
        id = "1";
        mode = "absolute_mouse";
        name = "";
        description = "";
        inputs.click.activators.Soft_Press = {
          bindings.binding = ["mouse_button LEFT, , "];
          settings.haptic_intensity = "1";
        };
        settings.sensitivity = "145";
        settings.doubetap_max_duration = "320";
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
          dpad_north.disabled_activators = {};
          dpad_south.activators.Full_Press = {
            bindings.binding = ["key_press S, , "];
            settings.repeat_rate = "99";
            settings.haptic_intensity = "1";
          };
          dpad_south.disabled_activators = {};
          dpad_east.activators.Full_Press = {
            bindings.binding = ["key_press E, , "];
            settings.repeat_rate = "99";
            settings.haptic_intensity = "1";
          };
          dpad_east.disabled_activators = {};
          dpad_west.activators.Full_Press = {
            bindings.binding = ["key_press Q, , "];
            settings.repeat_rate = "99";
            settings.haptic_intensity = "1";
          };
          dpad_west.disabled_activators = {};
          click.activators.Full_Press = {
            bindings.binding = ["key_press R, , "];
            settings.repeat_rate = "99";
            settings.haptic_intensity = "1";
          };
          click.disabled_activators = {};
        };
        settings.requires_click = "0";
        settings.edge_binding_radius = "24995";
      }
      {
        id = "3";
        mode = "trigger";
        name = "";
        description = "";
        inputs.click.activators.Full_Press = {
          bindings.binding = ["key_press LEFT_SHIFT, , "];
          settings.haptic_intensity = "2";
        };
        inputs.click.disabled_activators = {};
      }
      {
        id = "4";
        mode = "switches";
        name = "";
        description = "";
        inputs = {
          button_escape.activators.Full_Press.bindings.binding = ["key_press TAB, , "];
          button_escape.disabled_activators = {};
          button_menu.activators.Full_Press = {
            bindings.binding = ["key_press F8, , "];
            settings.toggle = "1";
          };
          button_menu.disabled_activators = {};
          left_bumper.activators.Full_Press = {
            bindings.binding = ["mouse_wheel SCROLL_UP, , "];
            settings.hold_repeats = "1";
            settings.repeat_rate = "10";
            settings.delay_start = "100";
          };
          left_bumper.disabled_activators = {};
          right_bumper.activators.Full_Press = {
            bindings.binding = ["mouse_wheel SCROLL_DOWN, , "];
            settings.hold_repeats = "1";
            settings.repeat_rate = "10";
            settings.delay_start = "100";
          };
          right_bumper.disabled_activators = {};
          button_back_left.activators.Full_Press.bindings.binding = ["key_press F3, , "];
          button_back_left.disabled_activators = {};
          button_back_right.activators.Full_Press.bindings.binding = ["key_press F4, , "];
          button_back_right.disabled_activators = {};
          button_back_left_upper.activators.Full_Press.bindings.binding = ["key_press F1, , "];
          button_back_left_upper.disabled_activators = {};
          button_back_right_upper.activators.Full_Press.bindings.binding = ["key_press F2, , "];
          button_back_right_upper.disabled_activators = {};
          right_trigger.activators.Full_Press = {
            bindings.binding = ["mode_shift right_trackpad 17"];
            settings.interruptable = "0";
          };
          right_trigger.disabled_activators = {};
          button_capture.activators.release.bindings.binding = ["controller_action system_key_1, , "];
          button_capture.disabled_activators = {};
        };
      }
      {
        id = "5";
        mode = "joystick_mouse";
        name = "";
        description = "";
        inputs.touch.activators.Full_Press.bindings.binding = ["mouse_button RIGHT, , "];
        inputs.touch.disabled_activators = {};
        settings.output_joystick = "2";
        settings.sensitivity_horiz_scale = "30";
        settings.sensitivity_vert_scale = "15";
      }
      {
        id = "6";
        mode = "scrollwheel";
        name = "";
        description = "";
        inputs = {
          scroll_wheel_list_0.activators.Full_Press.bindings.binding = ["key_press J, , "];
          scroll_wheel_list_0.disabled_activators = {};
          scroll_wheel_list_1.activators.Full_Press.bindings.binding = ["key_press L, , "];
          scroll_wheel_list_1.disabled_activators = {};
          scroll_wheel_list_2.activators.Full_Press.bindings.binding = ["key_press M, , "];
          scroll_wheel_list_2.disabled_activators = {};
          scroll_wheel_list_3.activators.Full_Press.bindings.binding = ["key_press I, , "];
          scroll_wheel_list_3.disabled_activators = {};
          scroll_wheel_list_4.activators.Full_Press.bindings.binding = ["key_press Y, , "];
          scroll_wheel_list_4.disabled_activators = {};
          scroll_wheel_list_5.activators.Full_Press.bindings.binding = ["key_press K, , "];
          scroll_wheel_list_5.disabled_activators = {};
          scroll_wheel_list_6.activators.Full_Press.bindings.binding = ["key_press B, , "];
          scroll_wheel_list_6.disabled_activators = {};
          scroll_wheel_list_7.activators.Full_Press.bindings.binding = ["key_press H, , "];
          scroll_wheel_list_7.disabled_activators = {};
        };
        settings.scroll_type = "2";
      }
      {
        id = "7";
        mode = "trigger";
        name = "";
        description = "";
        inputs.click.activators.Full_Press = {
          bindings.binding = ["controller_action hold_layer 2 1 1, , "];
          settings.haptic_intensity = "2";
        };
        inputs.click.disabled_activators = {};
      }
      {
        id = "8";
        mode = "four_buttons";
        name = "";
        description = "";
        inputs = {};
      }
      {
        id = "9";
        mode = "trigger";
        name = "";
        description = "";
        inputs = {};
      }
      {
        id = "10";
        mode = "trigger";
        name = "";
        description = "";
        inputs = {};
      }
      {
        id = "11";
        mode = "switches";
        name = "";
        description = "";
        inputs = {};
      }
      {
        id = "12";
        mode = "reference";
        description = "";
        settings.referenced_mode = "13";
      }
      {
        id = "13";
        mode = "touch_menu";
        name = "Skills";
        description = "";
        inputs = {
          touch_menu_button_0.activators.Full_Press = {
            bindings.binding = ["key_press 1, , "];
            settings.haptic_intensity = "2";
          };
          touch_menu_button_0.disabled_activators = {};
          touch_menu_button_1.activators.Full_Press = {
            bindings.binding = ["key_press 2, , "];
            settings.haptic_intensity = "2";
          };
          touch_menu_button_1.disabled_activators = {};
          touch_menu_button_2.activators.Full_Press = {
            bindings.binding = ["key_press 3, , "];
            settings.haptic_intensity = "2";
          };
          touch_menu_button_2.disabled_activators = {};
          touch_menu_button_3.activators.Full_Press = {
            bindings.binding = ["key_press 4, , "];
            settings.haptic_intensity = "2";
          };
          touch_menu_button_3.disabled_activators = {};
          touch_menu_button_4.activators.Full_Press = {
            bindings.binding = ["key_press 5, , "];
            settings.haptic_intensity = "2";
          };
          touch_menu_button_4.disabled_activators = {};
          touch_menu_button_5.activators.Full_Press = {
            bindings.binding = ["key_press 6, , "];
            settings.haptic_intensity = "2";
          };
          touch_menu_button_5.disabled_activators = {};
          touch_menu_button_6.activators.Full_Press = {
            bindings.binding = ["key_press 7, , "];
            settings.haptic_intensity = "2";
          };
          touch_menu_button_6.disabled_activators = {};
          touch_menu_button_7.activators.Full_Press = {
            bindings.binding = ["key_press 8, , "];
            settings.haptic_intensity = "2";
          };
          touch_menu_button_7.disabled_activators = {};
          touch_menu_button_8.activators.Full_Press = {
            bindings.binding = ["key_press 9, , "];
            settings.haptic_intensity = "2";
          };
          touch_menu_button_8.disabled_activators = {};
        };
        settings.gyro_button = "1";
      }
    ];
    # actions and layers are new
    actions.Default.title = "Default";
    actions.Default.legacy_set = "1";
    action_layers.Preset_1000001 = {
      title = "RT";
      legacy_set = "1";
      set_layer = "1";
      parent_set_name = "Default";
    };
    preset = [
      {
        id = "0";
        name = "Default";
        group_source_bindings = {
          "0" = "button_diamond active";
          "1" = "right_trackpad active";
          "2" = "joystick active";
          "3" = "left_trigger active";
          "4" = "switch active";
          "5" = "right_joystick active";
          "6" = "left_trackpad active";
          "7" = "right_trigger active";
        };
      }
      {
        id = "1";
        name = "Preset_1000001";
        group_source_bindings = {
          "8" = "button_diamond active";
          "9" = "left_trigger active";
          "10" = "right_trigger active";
          "11" = "switch active";
          "12" = "right_trackpad active";
        };
      }
    ];
    settings.left_trackpad_mode = "0";
    settings.right_trackpad_mode = "0";
  };
}
