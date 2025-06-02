{
  # TODO why do I need to explicitly start the pipewire-pulse service when the socket should activate it?
  dotfiles = {
    shared = {lib, ...}: {
      options.dotfiles.graphical.sound.enable = lib.mkEnableOption "Sound devices";
    };
    home-manager = {
      config,
      lib,
      pkgs,
      ...
    }: {
      config = lib.mkIf (config.dotfiles.graphical.sound.enable && pkgs.stdenv.hostPlatform.isLinux) {
        home.packages = with pkgs; [asak playerctl];
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
        };
      };
    };
    nixos = {
      config,
      lib,
      pkgs,
      ...
    }: {
      config = lib.mkIf config.dotfiles.graphical.sound.enable {
        assertions = lib.toList {
          assertion = config.dotfiles.graphical.enable;
          message = "Sound only makes sense if the node is graphical";
        };
        # TODO consider build https://github.com/schooldanlp6/marstui-rustio
        environment.systemPackages = [pkgs.pavucontrol];
        hardware.bluetooth.enable = true;
        # TODO should I do powerOnBoot and settings.General.Experimental?
        security.rtkit.enable = true;
        services.pipewire = {
          enable = true;
          alsa.enable = true;
          alsa.support32Bit = true;
          pulse.enable = true;
          jack.enable = true;
        };
      };
    };
  };
}
