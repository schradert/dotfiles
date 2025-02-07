{
  #   perSystem = {
  #     config,
  #     pkgs,
  #     ...
  #   }: {
  #     # TODO fix double tap yubikey to unlock (might need to default show hyprlock input)
  #     # TODO figure out how to configure this automatically -- should this be done every time?
  #     # Seems like this has to run with pcscd running
  #     packages.yubikey = config.canivete.scripts.yubikey.package;
  #     canivete.scripts.yubikey = {
  #       script = ./yubikey.sh;
  #       runtimeInputs = with pkgs; [yubikey-personalization yubico-pam yubikey-manager];
  #     };
  #   };
  canivete.deploy.nixos.modules.yubikey = {
    config,
    flake,
    lib,
    pkgs,
    ...
  }: {
    options.dotfiles.services.yubikey.enable = lib.mkEnableOption "YubiKey authentication for login, sudo, etc.";
    config = lib.mkIf config.dotfiles.services.yubikey.enable {
      environment.systemPackages = [pkgs.yubioath-flutter];
      home-manager.users.${flake.config.canivete.people.me}.pam.yubico.authorizedYubiKeys.ids = ["cccccbdeigfb"];
      programs.gnupg.agent = {
        enable = true;
        enableSSHSupport = true;
      };
      programs.yubikey-touch-detector.enable = true;
      security.pam.yubico = {
        enable = true;
        debug = true;
        mode = "challenge-response";
        # Determined with shell nixpkgs#yubikey-personalization --command ykinfo -s
        id = ["19100993"];
      };
      services = {
        yubikey-agent.enable = true;
        pcscd.enable = true;
        udev.packages = [pkgs.yubikey-personalization];
        # Lock screen when unplugged
        # TODO is there a better way to lock like with hyprlock?
        udev.extraRules = ''
          ACTION=="remove",\
            ENV{ID_BUS}=="usb",\
            ENV{ID_MODEL_ID}=="0407",\
            ENV{ID_VENDOR_ID}=="1050",\
            ENV{ID_VENDOR}=="Yubico",\
            RUN+="${pkgs.systemd}/bin/loginctl lock-sessions"
        '';
      };
    };
  };
}
