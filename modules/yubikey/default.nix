{
  perSystem = {
    config,
    pkgs,
    ...
  }: {
    packages.yubikey = config.canivete.scripts.yubikey.package;
    canivete.scripts.yubikey = {
      script = ./yubikey.sh;
      runtimeInputs = with pkgs; [yubikey-personalization yubico-pam yubikey-manager];
    };
  };
  canivete.deploy.system.homeModules.yubikey.pam.yubico.authorizedYubiKeys.ids = ["cccccbdeigfb"];
  canivete.deploy.nixos.modules.yubikey = {
    config,
    lib,
    pkgs,
    ...
  }: {
    config = lib.mkIf (config.dotfiles.graphical.enable) {
      environment.systemPackages = [pkgs.yubioath-flutter];
      programs.gnupg.agent = {
        enable = true;
        enableSSHSupport = true;
      };
      programs.yubikey-touch-detector.enable = true;
      security.pam.yubico = {
        enable = true;
        debug = true;
        mode = "challenge-response";
        id = ["19100993"];
      };
      services = {
        yubikey-agent.enable = true;
        pcscd.enable = true;
        udev.packages = [pkgs.yubikey-personalization];
        # Lock screen when unplugged
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
