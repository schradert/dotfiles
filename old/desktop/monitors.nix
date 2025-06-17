{
  # TODO figure out a proper arrangement of monitors to allow synchronized brightness control
  # NOTE DisplayLink seems to not work well with the DDC/CI standard, even though HDMI/USB is hinted to work
  # TODO create monitor name alias options
  # TODO https://github.com/MonitorControl/MonitorControl
  canivete.pkgs.allowUnfree = ["displaylink"];
  dotfiles = {
    shared = {lib, ...}: {
      options.dotfiles.graphical.monitors = lib.mkEnableOption "Graphical monitor setup at home";
    };
    nixos = {
      config,
      flake,
      lib,
      pkgs,
      ...
    }: {
      config = lib.mkIf config.dotfiles.graphical.monitors {
        boot.extraModulePackages = [config.boot.kernelPackages.ddcci-driver];
        boot.kernelModules = ["ddcci_backlight"];
        environment.systemPackages = with pkgs; [brightnessctl ddcutil];
        hardware.acpilight.enable = true;
        hardware.brillo.enable = true;
        hardware.i2c.enable = config.dotfiles.graphical.monitors;
        programs.light.enable = true;
        programs.light.brightnessKeys.enable = true;
        services.ddccontrol.enable = true;
        services.redshift.enable = true;
        users.users.${flake.config.canivete.meta.people.me}.extraGroups = ["i2c"];
      };
    };
    home-manager = {
      config,
      lib,
      pkgs,
      ...
    }: let
      inherit (lib) flip getExe concatStringsSep map pipe;
    in {
      config = lib.mkIf config.dotfiles.graphical.monitors {
        wayland.windowManager.hyprland.settings = let
          LGW = 3840;
          LGH = 2160;
          offsetY = 400;
          base = 1.50;
          zoom = 3.00;
          # TODO round numbers or find the closest available mode (could this be what's causing the aberrations on lock screen? is there lag because of this too?)
          monitorCfgs = scale: [
            "desc:LG Electronics LG HDR 4K 205NTDVH0506, ${toString LGW}x${toString LGH}@60.00, 0x0, ${toString scale}, transform, 1"
            "desc:LG Electronics LG ULTRAFINE 111NTUWFF862, ${toString LGW}x${toString LGH}@60.00, ${toString (LGH / scale)}x${toString (offsetY / scale)}, ${toString scale}"
            "desc:LG Display 0x04B9, 1920x1080@60.02, ${toString ((LGH + LGW) / scale)}x${toString (2 * offsetY / scale)}, ${toString scale}"
          ];
          monitorCmds = flip pipe [
            monitorCfgs
            (map (monitor: "keyword monitor \"${monitor}\""))
            (concatStringsSep " ; ")
          ];
          script = pkgs.writeShellApplication {
            name = "hyprland-scale-monitors";
            runtimeInputs = [pkgs.jq config.wayland.windowManager.hyprland.finalPackage];
            text = ''
              hyprctl --batch "$(
                  if [[ "$(hyprctl -j monitors | jq '.[0].scale')" == "$(printf '%.2f' "${toString base}")" ]]; then
                      echo "${monitorCmds zoom}"
                  else
                      echo "${monitorCmds base}"
                  fi
              )"
            '';
          };
        in {
          monitor = monitorCfgs base;
          bind = ["$mod+SHIFT, z, exec, ${getExe script}"];
          workspace = [
            "1, monitor:desc:LG Electronics LG HDR 4K 205NTDVH0506"
            "2, monitor:desc:LG Electronics LG HDR 4K 205NTDVH0506"
            "3, monitor:desc:LG Electronics LG HDR 4K 205NTDVH0506"
            "4, monitor:desc:LG Electronics LG HDR 4K 205NTDVH0506"
            "5, monitor:desc:LG Electronics LG ULTRAFINE 111NTUWFF862"
            "6, monitor:desc:LG Electronics LG ULTRAFINE 111NTUWFF862"
            "7, monitor:desc:LG Electronics LG ULTRAFINE 111NTUWFF862"
            "8, monitor:desc:LG Electronics LG ULTRAFINE 111NTUWFF862"
            "9, monitor:desc:LG Display 0x04B9"
            "10, monitor:desc:LG Display 0x04B9"
            "11, monitor:desc:LG Display 0x04B9"
            "12, monitor:desc:LG Display 0x04B9"

            "$mod, F1, workspace, 01"
            "$mod, F2, workspace, 02"
            "$mod, F3, workspace, 03"
            "$mod, F4, workspace, 04"
            "$mod, F5, workspace, 05"
            "$mod, F6, workspace, 06"
            "$mod, F7, workspace, 07"
            "$mod, F8, workspace, 08"
            "$mod, F9, workspace, 09"
            "$mod, F10, workspace, 10"
            "$mod, F11, workspace, 11"
            "$mod, F12, workspace, 12"
          ];
        };
      };
    };
  };
}
