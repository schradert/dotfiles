{
  # TODO why do I need to explicitly start the pipewire-pulse service when the socket should activate it?
  canivete.deploy.nixos.modules.sound = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) mkEnableOption mkIf toList;
  in {
    options.dotfiles.graphical.sound.enable = mkEnableOption "Sound devices";
    config = mkIf config.dotfiles.graphical.sound.enable {
      assertions = toList {
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
      home-manager.sharedModules = toList {
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
  };
}
