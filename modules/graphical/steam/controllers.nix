{lib, pkgs, ...}: let
  inherit (lib) any evalModules flip mapAttrsToList mkOption types toLower nameValuePair imap0 pipe listToAttrs setAttrByPath imap1 attrNames removeAttrs concat mergeAttrs getAttr flatten optional attrVals;
  inherit (types) anything coercedTo str int submodule listOf attrsOf nullOr enum package oneOf;
  inherit ((evalModules {inherit modules;}).config.out) json;
  intStr = coercedTo int builtins.toString str;
  title = "The Legend of Pirates Online";
  activator = mkOption {
    default = null;
    type = nullOr (submodule {
      options.bindings = mkOption {
        type = listOf (submodule {
          options.binding = mkOption {type = str;};
        });
      };
      options.settings = mkOption {
        default = {};
        type = nullOr (submodule {
          options = {
            hold_repeats = mkOption {
              type = nullOr (enum ["1"]);
              default = null;
            };
            interruptable = mkOption {
              type = nullOr (enum ["0"]);
              default = null;
            };
            toggle = mkOption {
              type = nullOr (enum ["1"]);
              default = null;
            };
            repeat_rate = mkOption {
              type = nullOr intStr;
              default = null;
            };
            delay_start = mkOption {
              type = nullOr intStr;
              default = null;
            };
            haptic_intensity = mkOption {
              type = nullOr intStr;
              default = null;
            };
          };
        });
      };
    });
  };
  activators = submodule {
    options = {
      Full_Press = activator;
      Soft_Press = activator;
      release = activator;
    };
  };
  button = mkOption {
    default = null;
    type = nullOr (submodule {
      options.activators = mkOption {type = activators; default = {};};
      options.disabled_activators = mkOption {type = activators; default = {};};
    });
  };
  four_buttons = submodule {
    options = {
      id = mkOption {type = intStr;};
      name = mkOption {type = str; default = "";};
      description = mkOption {type = str; default = "";};
      mode = mkOption {type = enum ["four_buttons"]; readOnly = true; default = "four_buttons";};
      settings = mkOption {
        type = submodule {
          options.button_size = mkOption {type = enum ["17994"]; default = "17994";};
          options.button_dist = mkOption {type = enum ["19994"]; default = "19994";};
        };
      };
      inputs = mkOption {
        default = {};
        type = submodule {
          options = {
            button_a = button;
            button_b = button;
            button_x = button;
            button_y = button;
          };
        };
      };
    };
  };
  dpad = submodule {
    options = {
      id = mkOption {type = intStr;};
      name = mkOption {type = str; default = "";};
      description = mkOption {type = str; default = "";};
      mode = mkOption {type = enum ["dpad"]; readOnly = true; default = "dpad";};
      settings = mkOption {
        type = submodule {
          options.edge_binding_radius = mkOption {type = nullOr intStr; default = null;};
          options.requires_click = mkOption {type = nullOr (enum ["0"]); default = null;};
          options.haptic_intensity_override = mkOption {type = nullOr (enum ["0"]); default = null;};
        };
      };
      inputs = mkOption {
        default = {};
        type = submodule {
          options = {
            dpad_north = button;
            dpad_south = button;
            dpad_east = button;
            dpad_west = button;
            click = button;
          };
        };
      };
    };
  };
  absolute_mouse = submodule {
    options = {
      id = mkOption {type = intStr;};
      name = mkOption {type = str; default = "";};
      description = mkOption {type = str; default = "";};
      mode = mkOption {type = enum ["absolute_mouse"]; readOnly = true; default = "absolute_mouse";};
      settings = mkOption {
        type = submodule {
          options.sensitivity = mkOption {type = intStr; default = 145;};
          options.doubetap_max_duration = mkOption {type = intStr; default = 320;};
        };
      };
      inputs = mkOption {
        default = {};
        type = submodule {
          options.click = button;
        };
      };
    };
  };
  trigger = submodule {
    options = {
      id = mkOption {type = intStr;};
      name = mkOption {type = str; default = "";};
      description = mkOption {type = str; default = "";};
      mode = mkOption {type = enum ["trigger"]; readOnly = true; default = "trigger";};
      inputs = mkOption {
        default = {};
        type = submodule {
          options.click = button;
        };
      };
    };
  };
  joystick_mouse = submodule {
    options = {
      id = mkOption {type = intStr;};
      name = mkOption {type = str; default = "";};
      description = mkOption {type = str; default = "";};
      mode = mkOption {type = enum ["joystick_mouse"]; readOnly = true; default = "joystick_mouse";};
      settings = mkOption {
        type = submodule {
          options.output_joystick = mkOption {type = intStr; default = 2;};
          options.sensitivity_horiz_scale = mkOption {type = nullOr intStr; default = null;};
          options.sensitivity_vert_scale = mkOption {type = nullOr intStr; default = null;};
        };
      };
      inputs = mkOption {
        default = {};
        type = submodule {
          options.touch = button;
        };
      };
    };
  };
  scrollwheel = submodule {
    options = {
      id = mkOption {type = intStr;};
      name = mkOption {type = str; default = "";};
      description = mkOption {type = str; default = "";};
      mode = mkOption {type = enum ["scrollwheel"]; readOnly = true; default = "scrollwheel";};
      settings = mkOption {
        type = submodule {
          options.scroll_type = mkOption {type = intStr; default = 2;};
        };
      };
      inputs = mkOption {
        default = {};
        type = submodule {
          options = {
            scroll_wheel_list_0 = button;
            scroll_wheel_list_1 = button;
            scroll_wheel_list_2 = button;
            scroll_wheel_list_3 = button;
            scroll_wheel_list_4 = button;
            scroll_wheel_list_5 = button;
            scroll_wheel_list_6 = button;
            scroll_wheel_list_7 = button;
          };
        };
      };
    };
  };
  touch_menu = submodule {
    options = {
      id = mkOption {type = intStr;};
      name = mkOption {type = str;};
      description = mkOption {type = str; default = "";};
      mode = mkOption {type = enum ["touch_menu"]; readOnly = true; default = "touch_menu";};
      settings = mkOption {
        type = submodule {
          options.gyro_button = mkOption {type = intStr; default = 1;};
        };
      };
      inputs = mkOption {
        default = {};
        type = submodule {
          options = {
            touch_menu_button_0 = button;
            touch_menu_button_1 = button;
            touch_menu_button_2 = button;
            touch_menu_button_3 = button;
            touch_menu_button_4 = button;
            touch_menu_button_5 = button;
            touch_menu_button_6 = button;
            touch_menu_button_7 = button;
          };
        };
      };
    };
  };
  reference = submodule {
    options = {
      id = mkOption {type = intStr;};
      description = mkOption {type = str; default = "";};
      mode = mkOption {type = enum ["reference"]; readOnly = true; default = "reference";};
      settings = mkOption {
        type = submodule {
          options.referenced_mode = mkOption {type = intStr;};
        };
      };
    };
  };
  switches = submodule {
    options = {
      id = mkOption {type = intStr;};
      name = mkOption {type = str; default = "";};
      description = mkOption {type = str; default = "";};
      mode = mkOption {type = enum ["switches"]; readOnly = true; default = "switches";};
      inputs = mkOption {
        default = {};
        type = submodule {
          options = {
            button_escape = button;
            button_menu = button;
            left_bumper = button;
            right_bumper = button;
            button_back_left = button;
            button_back_right = button;
            button_back_left_upper = button;
            button_back_right_upper = button;
            right_trigger = button;
            button_capture = button;
          };
          config.button_capture.activator.release.bindings.binding = "controller_action system_key_1, , ";
        };
      };
    };
  };
  modules = [
    {
      menus.Skills.touch = [
        "key_press 1"
        "key_press 2"
        "key_press 3"
        "key_press 4"
        "key_press 5"
        "key_press 6"
        "key_press 7"
        "key_press 8"
        "key_press 9"
      ];
      sets.Default.layers = {
        RT.RP.menu = "Skills";
        Default = {
          ESC.Full_Press.bindings = ["key_press TAB"];
          MENU.Full_Press = {
            bindings = ["key_press F8"];
            toggle = "1";
          };
          A.Full_Press.bindings = ["key_press SPACE"];
          B.Full_Press.bindings = ["key_press ESCAPE"];
          X.Full_Press.bindings = ["mouse_button LEFT"];
          Y.Full_Press.bindings = ["key_press T"];
          RB.Full_Press = {
            bindings = ["mouse_wheel SCROLL_DOWN"];
            hold_repeats = "1";
            repeat_rate = "10";
            delay_start = "100";
          };
          LB.Full_Press = {
            bindings = ["mouse_wheel SCROLL_UP"];
            hold_repeats = "1";
            repeat_rate = "10";
            delay_start = "100";
          };
          LT.Full_Press.bindings = ["key_press LEFT_SHIFT"];
          RT.Full_Press.layer = "RT";
          L4.Full_Press.bindings = ["key_press F1"];
          R4.Full_Press.bindings = ["key_press F2"];
          L5.Full_Press.bindings = ["key_press F3"];
          R5.Full_Press.bindings = ["key_press F4"];
          LP.scrollwheel = [
            "key_press J"
            "key_press L"
            "key_press M"
            "key_press I"
            "key_press Y"
            "key_press K"
            "key_press B"
            "key_press H"
          ];
          RP.absolute_mouse.click.Soft_Press.bindings = ["mouse_button LEFT"];
          LJ.dpad = {
            dpad_north.Full_Press.bindings = ["key_press W"];
            dpad_south.Full_Press.bindings = ["key_press S"];
            dpad_east.Full_Press.bindings = ["key_press E"];
            dpad_west.Full_Press.bindings = ["key_press Q"];
            click.Full_Press.bindings = ["key_press R"];
          };
          RJ.joystick_mouse.touch.Full_Press.bindings = ["mouse_button RIGHT"];
        };
      };
    }
    {
      options.out.raw = mkOption {
        default = {};
        type = submodule {
          freeformType = str;
          options = {
            version = mkOption {
              type = intStr;
              readOnly = true;
              default = 3;
            };
            revision = mkOption {
              type = intStr;
              readOnly = true;
              default = 1;
            };
            title = mkOption {
              type = str;
              default = "#Title";
            };
            description = mkOption {
              type = str;
              default = "#SettingsController_AutosaveDescription";
            };
            export_type = mkOption {
              type = enum ["unknown"];
              default = "unknown";
            };
            controller_type = mkOption {
              type = enum ["controller_neptune"];
              default = "controller_neptune";
            };
            # TODO what does this even mean?
            controller_caps = mkOption {
              type = enum ["23117823"];
              default = "23117823";
            };
            settings = mkOption {
              type = attrsOf str;
              default = {};
            };
            localization.english.title = mkOption {
              type = str;
              default = title;
            };
            preset = mkOption {
              type = listOf (submodule {
                options.id = mkOption {type = intStr;};
                options.name = mkOption {type = str;};
                options.group_source_bindings = mkOption {type = attrsOf str;};
              });
            };
            actions = mkOption {
              type = attrsOf (submodule ({name, ...}: {
                options.title = mkOption {
                  type = str;
                  default = name;
                };
                options.legacy_set = mkOption {type = intStr;};
              }));
            };
            action_layers = mkOption {
              type = attrsOf (submodule {
                options = {
                  title = mkOption {type = str;};
                  legacy_set = mkOption {type = intStr;};
                  set_layer = mkOption {type = intStr;};
                  parent_set_name = mkOption {type = str;};
                };
              });
            };
            group = mkOption {
              type = listOf (oneOf [
                four_buttons
                dpad
                trigger
                reference
                touch_menu
                scrollwheel
                joystick_mouse
                absolute_mouse
                switches
              ]);
            };
          };
          config = {
            # TODO generate creator and url dynamically
            # TODO where does creator come from?
            # creator = "76561198274817622";
            # url = "autosave:///home/tristan/.local/share/Steam/steamapps/common/Steam Controller Configs/314551894/config/${toLower title}/controller_neptune.vdf";
            # TODO is progenitor necessary?
            progenitor = "template://controller_neptune_wasd.vdf";
            major_revision = "0";
            minor_revision = "0";
            Timestamp = "0";
            settings.left_trackpad_mode = "0";
            settings.right_trackpad_mode = "0";
          };
        };
      };
    }
    ({config, ...}: {
      options.out.json = mkOption {
        type = package;
        readOnly = true;
        # TODO remove nulls recursively
        default = (pkgs.formats.json {}).generate "controls.json" {controller_mappings = config.out.raw;};
      };
    })
    ({config, ...}: {
      options.menus = mkOption {
        default = {};
        type = attrsOf (submodule {
          options.touch = mkOption {
            type = listOf str;
            default = [];
          };
        });
      };
      config.out.raw.group = flip mapAttrsToList config.menus (name: menu: {
        mode = "touch_menu";
        inherit name;
        description = "";
        settings.gyro_button = "1";
        inputs = pipe menu.touch [
          (imap0 (i: binding: nameValuePair "touch_menu_button_${i}" {
            disabled_activators = {};
            activators.Full_Press.bindings.binding = "${binding}, , ";
            activators.Full_Press.settings.haptic_intensity = "2";
          }))
          listToAttrs
        ];
      });
    })
    ({config, ...}: let
      basicButton = mkOption {
        default = null;
        type = nullOr (coercedTo str (setAttrByPath ["binding"]) (submodule {
          freeformType = str;
          options.binding = mkOption {type = nullOr str;};
        }));
      };
      ABXY = mkOption {
        default = null;
        type = nullOr (coercedTo (submodule {

        }) (binding: {
          activators.Full_Press.bindings = [{binding = "${binding}, , ";}];
          activators.Full_Press.settings.repeat_rate = 99;
        }) button);
      };
      actions = pipe config.sets [
        (flip removeAttrs ["Default"])
        attrNames
        (concat ["Default"])
        (imap1 (i: flip nameValuePair {layer_set = i;}))
        listToAttrs
      ];
      action_layers = pipe config.sets [
        (mapAttrsToList (parent_set_name: flip pipe [
          (getAttr "layers")
          (flip removeAttrs ["Default"])
          (mapAttrsToList (title: layer: {
            inherit title parent_set_name;
            inherit (actions.${parent_set_name}) layer_set;
          }))
          (imap1 (i: mergeAttrs {set_layer = i;}))
        ]))
        flatten
        (imap1 (i: nameValuePair "Preset_${toString (1000000 + i)}"))
        listToAttrs
      ];
      preset = pipe action_layers [
        attrNames
        # TODO what about Defaults in other action sets?
        # TODO group_source_bindings
        (concat ["Default"])
        (imap0 (id: name: {inherit id name;}))
      ];
      notNull = value: value != null;
      group = pipe config.sets [
        (mapAttrsToList (parent_set_name: set: flip pipe [
          (getAttr "layers")
          (mapAttrsToList (title: layer: [
            (pipe layer [
              (attrVals ["A" "B" "X" "Y"])
              (any notNull)
              (flip optional {
                mode = "four_buttons";
                settings.button_size = "17994";
                settings.button_dist = "19994";
                inputs = {
                  button_a = layer.A;
                  button_b = layer.B;
                  button_x = layer.X;
                  button_y = layer.Y;
                };
              })
            ])
            (pipe layer [
              (attrVals ["MENU" "ESC" "LB" "RB" "L5" "R5" "L4" "R4" "RT"])
              (any notNull)
              (flip optional {
                mode = "switches";
                inputs = {
                  button_escape = layer.ESC;
                  button_menu = layer.MENU;
                  left_bumper = layer.LB;
                  right_bumper = layer.RB;
                  button_back_left = layer.L5;
                  button_back_right = layer.R5;
                  button_back_left_upper = layer.L4;
                  button_back_right_upper = layer.R4;
                  right_trigger = layer.RT;
                };
              })
            ])
            (pipe layer [
              (attrVals ["LT"])
              (any notNull)
              (flip optional {
                mode = "trigger";
                inputs = if layer.LT != null then layer.LT else {};
              })
            ])
          ]))
        ]))
        flatten
        (imap0 (id: mergeAttrs {inherit id;}))
      ];
    in {
      config.sets.Default.layers.Default = {};
      config.out.raw = {inherit actions action_layers preset group;};
      options.sets = mkOption {
        type = attrsOf (submodule {
          options.layers = mkOption {
            type = attrsOf (submodule {
              options = {
                MENU = basicButton;
                ESC = basicButton;
                A = ABXY;
                B = ABXY;
                X = ABXY;
                Y = ABXY;
                DN = basicButton;
                DS = basicButton;
                DE = basicButton;
                DW = basicButton;
                RB = basicButton;
                RT = basicButton;
                R3 = basicButton;
                R4 = basicButton;
                R5 = basicButton;
                RJ = basicButton;
                RP = basicButton;
                LB = basicButton;
                LT = basicButton;
                L3 = basicButton;
                L4 = basicButton;
                L5 = basicButton;
                LJ = basicButton;
                LP = basicButton;
              };
            });
          };
        });
      };
    })
  ];
in {}
