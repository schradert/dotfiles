{
  # TODO why do I need to explicitly start the pipewire-pulse service when the socket should activate it?
  canivete.deploy.nixos.modules.sound = {
    config,
    lib,
    pkgs,
    ...
  }: {
    options.dotfiles.graphical.sound.enable = lib.mkEnableOption "Sound devices";
    config = lib.mkIf config.dotfiles.graphical.sound.enable {
      environment.systemPackages = [pkgs.pavucontrol];
      hardware.bluetooth.enable = true;
      security.rtkit.enable = true;
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        jack.enable = true;
      };
      home-manager.sharedModules = lib.toList {
        home.packages = [pkgs.playerctl];
        services.playerctld.enable = true;
        wayland.windowManager.hyprland.settings = {
          bindl = [
            ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
            ", XF86AudioNext, exec, playerctl next"
            ", XF86AudioPrev, exec, playerctl previous"
            ", XF86AudioStop, exec, playerctl --all-players stop"
            ", XF86AudioPlay, exec, playerctl play-pause"
          ];
          bindel = [
            ", XF86AudioRaiseVolume, exec, wpctl set-volume --limit 1.2 @DEFAULT_AUDIO_SINK@ 5%+"
            ", XF86AudioLowerVolume, exec, wpctl set-volume --limit 1.2 @DEFAULT_AUDIO_SINK@ 5%-"
          ];
          bindeol = [
            ", XF86AudioNext, exec, playerctl position 5+"
            ", XF86AudioPrev, exec, playerctl position 5-"
          ];
        };
      };
    };
  };
}
