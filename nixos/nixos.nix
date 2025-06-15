{
  dotfiles.nixos = {
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    i18n.defaultLocale = "en_US.UTF-8";
    system.stateVersion = "25.05";
    time.timeZone = "America/Los_Angeles";
  };
}
