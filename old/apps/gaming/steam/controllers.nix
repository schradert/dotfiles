{
  lib,
  inputs,
  ...
}: let
  pkgs = {};
  inherit (lib) any evalModules flip mapAttrsToList mkOption types nameValuePair imap0 pipe listToAttrs imap1 attrNames removeAttrs concat mergeAttrs getAttr flatten optional attrVals;
  inherit (types) coercedTo str int submodule listOf attrsOf nullOr enum package oneOf;
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
      options.activators = mkOption {
        type = activators;
        default = {};
      };
      options.disabled_activators = mkOption {
        type = activators;
        default = {};
      };
    });
  };
  four_buttons = submodule {
    options = {
      id = mkOption {type = intStr;};
      name = mkOption {
        type = str;
        default = "";
      };
      description = mkOption {
        type = str;
        default = "";
      };
      mode = mkOption {
        type = enum ["four_buttons"];
        readOnly = true;
        default = "four_buttons";
      };
      settings = mkOption {
        type = submodule {
          options.button_size = mkOption {
            type = enum ["17994"];
            default = "17994";
          };
          options.button_dist = mkOption {
            type = enum ["19994"];
            default = "19994";
          };
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
      name = mkOption {
        type = str;
        default = "";
      };
      description = mkOption {
        type = str;
        default = "";
      };
      mode = mkOption {
        type = enum ["dpad"];
        readOnly = true;
        default = "dpad";
      };
      settings = mkOption {
        type = submodule {
          options.edge_binding_radius = mkOption {
            type = nullOr intStr;
            default = null;
          };
          options.requires_click = mkOption {
            type = nullOr (enum ["0"]);
            default = null;
          };
          options.haptic_intensity_override = mkOption {
            type = nullOr (enum ["0"]);
            default = null;
          };
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
      name = mkOption {
        type = str;
        default = "";
      };
      description = mkOption {
        type = str;
        default = "";
      };
      mode = mkOption {
        type = enum ["absolute_mouse"];
        readOnly = true;
        default = "absolute_mouse";
      };
      settings = mkOption {
        type = submodule {
          options.sensitivity = mkOption {
            type = intStr;
            default = 145;
          };
          options.doubetap_max_duration = mkOption {
            type = intStr;
            default = 320;
          };
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
      name = mkOption {
        type = str;
        default = "";
      };
      description = mkOption {
        type = str;
        default = "";
      };
      mode = mkOption {
        type = enum ["trigger"];
        readOnly = true;
        default = "trigger";
      };
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
      name = mkOption {
        type = str;
        default = "";
      };
      description = mkOption {
        type = str;
        default = "";
      };
      mode = mkOption {
        type = enum ["joystick_mouse"];
        readOnly = true;
        default = "joystick_mouse";
      };
      settings = mkOption {
        type = submodule {
          options.output_joystick = mkOption {
            type = intStr;
            default = 2;
          };
          options.sensitivity_horiz_scale = mkOption {
            type = nullOr intStr;
            default = null;
          };
          options.sensitivity_vert_scale = mkOption {
            type = nullOr intStr;
            default = null;
          };
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
      name = mkOption {
        type = str;
        default = "";
      };
      description = mkOption {
        type = str;
        default = "";
      };
      mode = mkOption {
        type = enum ["scrollwheel"];
        readOnly = true;
        default = "scrollwheel";
      };
      settings = mkOption {
        type = submodule {
          options.scroll_type = mkOption {
            type = intStr;
            default = 2;
          };
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
      description = mkOption {
        type = str;
        default = "";
      };
      mode = mkOption {
        type = enum ["touch_menu"];
        readOnly = true;
        default = "touch_menu";
      };
      settings = mkOption {
        type = submodule {
          options.gyro_button = mkOption {
            type = intStr;
            default = 1;
          };
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
      description = mkOption {
        type = str;
        default = "";
      };
      mode = mkOption {
        type = enum ["reference"];
        readOnly = true;
        default = "reference";
      };
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
      name = mkOption {
        type = str;
        default = "";
      };
      description = mkOption {
        type = str;
        default = "";
      };
      mode = mkOption {
        type = enum ["switches"];
        readOnly = true;
        default = "switches";
      };
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
  groups = oneOf [
    four_buttons
    dpad
    trigger
    reference
    touch_menu
    scrollwheel
    joystick_mouse
    absolute_mouse
    switches
  ];
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
            group = mkOption {type = listOf groups;};
          };
          config = {
            # seems like creator and progenitor are not necessary
            # progenitor = "template://controller_neptune_wasd.vdf";
            # creator = "76561198274817622";
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
        inputs = pipe menu.touch [
          (imap0 (i: binding:
            nameValuePair "touch_menu_button_${i}" {
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
        type = nullOr (coercedTo str (binding: {activators.Full_Press.bindings = [{binding = "${binding}, , ";}];}) button);
      };
      actions = pipe config.sets [
        (flip removeAttrs ["Default"])
        attrNames
        (concat ["Default"])
        (imap1 (i: flip nameValuePair {layer_set = i;}))
        listToAttrs
      ];
      action_layers = pipe config.sets [
        (mapAttrsToList (parent_set_name:
          flip pipe [
            (getAttr "layers")
            (flip removeAttrs ["Default"])
            (mapAttrsToList (title: _: {
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
        (mapAttrsToList (_: _:
          flip pipe [
            (getAttr "layers")
            (mapAttrsToList (_: layer: [
              (pipe layer [
                (attrVals ["LT"])
                (any notNull)
                (flip optional {
                  mode = "trigger";
                  inputs =
                    if layer.LT != null
                    then layer.LT
                    else {};
                })
              ])
            ]))
          ]))
        flatten
        (imap0 (id: mergeAttrs {inherit id;}))
      ];
      button_diamond = submodule ({config, ...}: {
        options = let
          ABXY = mkOption {
            default = null;
            # TODO convert to more than a string
            type = nullOr (coercedTo str (binding: {
                activators.Full_Press.bindings = [{binding = "${binding}, , ";}];
                activators.Full_Press.settings.repeat_rate = 99;
              })
              button);
          };
        in {
          A = ABXY;
          B = ABXY;
          X = ABXY;
          Y = ABXY;
        };
        config.groups.button_diamond = {
          mode = "four_buttons";
          settings.button_size = "17994";
          settings.button_dist = "19994";
          inputs = {
            button_a = config.A;
            button_b = config.B;
            button_x = config.X;
            button_y = config.Y;
          };
        };
      });
      button_dpad = submodule ({config, ...}: {
        options = {
          DN = basicButton;
          DS = basicButton;
          DE = basicButton;
          DW = basicButton;
        };
        config.groups.dpad = {
          mode = "dpad";
          inputs = {
            dpad_north = config.DN;
            dpad_south = config.DS;
            dpad_east = config.DE;
            dpad_west = config.DW;
          };
        };
      });
      button_switches = submodule ({config, ...}: {
        options = {
          MENU = basicButton;
          ESC = basicButton;
          LB = basicButton;
          L4 = basicButton;
          L5 = basicButton;
          RB = basicButton;
          R4 = basicButton;
          R5 = basicButton;
        };
        config.groups.switches = {
          mode = "switches";
          inputs = {
            button_escape = config.ESC;
            button_menu = config.MENU;
            left_bumper = config.LB;
            right_bumper = config.RB;
            button_back_left = config.L5;
            button_back_right = config.R5;
            button_back_left_upper = config.L4;
            button_back_right_upper = config.R4;
          };
        };
      });
      left_joystick = submodule ({config, ...}: {
        options.LJ = basicButton;
        options.L3 = basicButton;
        config.groups.left_joystick = {
          mode = "";
          inputs = {};
        };
      });
      right_joystick = submodule ({config, ...}: {
        options.RJ = basicButton;
        options.R3 = basicButton;
        config.groups.right_joystick = {
          mode = "";
          inputs = {};
        };
      });
      left_trackpad = submodule ({config, ...}: {
        options.LT = basicButton;
        config.groups.left_trackpad = {
          mode = "";
          inputs = {};
        };
      });
      right_trackpad = submodule ({config, ...}: {
        options.RP = basicButton;
        config.groups.right_trackpad = {
          mode = "";
          inputs = {};
        };
      });
      left_trigger = submodule ({config, ...}: {
        options.LT = basicButton;
        config.groups.left_trigger = {
          mode = "trigger";
          inputs = {};
        };
      });
      right_trigger = submodule ({config, ...}: {
        options.RT = basicButton;
        config.groups.right_trigger = {
          mode = "trigger";
          inputs = {};
        };
      });
    in {
      config.sets.Default.layers.Default = {};
      config.out.raw = {inherit actions action_layers preset group;};
      options.sets = mkOption {
        type = attrsOf (submodule {
          options.layers = mkOption {
            type = attrsOf (submodule {
              imports = [
                button_diamond
                button_dpad
                button_switches
                left_joystick
                left_trackpad
                left_trigger
                right_joystick
                right_trackpad
                right_trigger
              ];
              options = {
                groups = mkOption {
                  type = attrsOf groups;
                  default = {};
                };
              };
            });
          };
        });
      };
    })
  ];
in {
  dotfiles.devenv.git-hooks.hooks.typos.settings.ignored-words = ["interruptable"];
  flake.overlays.json2vdf = final: _: {
    json2vdf = final.writers.writePython3Bin "json2vdf" {libraries = [final.python3Packages.vdf];} ''
      from json import loads
      from sys import stdin, stdout
      from vdf import dumps, VDFDict


      def recurse(obj, key=None):
          if isinstance(obj, list):
              return [(key, recurse(val, key)[0][1]) for val in obj]
          elif isinstance(obj, dict):
              value = VDFDict([
                  pair for _key, val in obj.items()
                  for pair in recurse(val, _key)
              ])
              return [(key, value)] if key else value
          return [(key, obj)]


      data = recurse(loads(stdin.read()))
      stdout.write(dumps(data, pretty=True))
    '';
  };
}
