{
  # TODO figure out a proper arrangement of monitors to allow synchronized brightness control
  # NOTE DisplayLink seems to not work well with the DDC/CI standard, even though HDMI/USB is hinted to work
  canivete.deploy.nixos = {
    modules.monitors = {config, flake, lib, pkgs, ...}: {
      options.dotfiles.graphical.monitors = lib.mkEnableOption "Graphical monitor setup at home";
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
        users.users.${flake.config.canivete.people.me}.extraGroups = ["i2c"];
      };
    };
    homeModules.monitors = {config, lib, pkgs, ...}: let
      inherit (lib) flip getExe mkIf concatStringsSep map pipe;
    in {
      config = lib.mkIf config.dotfiles.graphical.monitors {
        wayland.windowManager.hyprland.settings = let
          LGW = 3840;
          LGH = 2160;
          offsetY = 400;
          base = 1.50;
          zoom = 3.00;
          monitorCfgs = scale: [
            "DVI-I-1, ${toString LGW}x${toString LGH}@60.00, 0x0, ${toString scale}, transform, 1"
            "DVI-I-2, ${toString LGW}x${toString LGH}@60.00, ${toString (LGH / scale)}x${toString (offsetY / scale)}, ${toString scale}"
            "eDP-1, 1920x1080@60.02, ${toString ((LGH + LGW) / scale)}x${toString (2 * offsetY / scale)}, ${toString scale}"
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
                  if [[ "$(hyprctl -j monitors eDP-1 | jq ".[0].scale")" == "$(printf "%.2f" "${toString base}")" ]]; then
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
        };
      };
    };
  };
}
