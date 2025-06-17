{
  dotfiles.nixos = {
    i18n.defaultLocale = "en_US.UTF-8";
    services.earlyoom.enable = true;
    system.stateVersion = "25.11";
    time.timeZone = "America/Los_Angeles";
  };
}
