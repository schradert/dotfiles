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
    };
  };
}
