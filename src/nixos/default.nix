{ self, config, pkgs, sops-nix, ... }:
{
  flake = {
    nixosModules.common = {
      imports = [
        self.nixosModules.home-manager
        sops-nix.nixosModules.sops
      ];
      users.users.${config.people.myself} = {
        isNormalUser = true;
        home = "/home/${config.people.myself}";
        description = config.people.users.${config.people.myself}.name;
        extraGroups = [ "wheel" "tty" ];
        shell = pkgs.zsh;
        openssh.authorizedKeys.keys = config.people.users.${config.people.myself}.sshKeys;
      };
      home-manager.users.${config.people.myself} = {
        imports = [ self.homeModules.common ];
        home.packages = with pkgs; [ nethogs protonvpn-cli ];
        services.emacs = { enable = true; defaultEditor = true; };
      };
      environment.pathsToLink = [ "/share/zsh" ];
      environment.shells = [ pkgs.zsh ];
      home-manager.useUserPackages = true;
      home-manager.useGlobalPkgs = true;
      users.users.root.openssh.authorizedKeys.keys = config.people.users.${config.people.myself}.sshKeys;
      users.mutableUsers = true;
      sops.defaultSopsFile = ../../conf/secrets.json;
      sops.defaultSopsFormat = "json";
      services.openssh.enable = true;
      system.stateVersion = "22.11";
      security.polkit.enable = true;
      security.pam.enableSSHAgentAuth = true;
      virtualisation.podman = { enable = true; dockerSocket.enable = true; defaultNetwork.settings.dns_enable = true; };
      time.timeZone = "America/Los_Angeles";
      i18n.defaultLocale = "en_US.UTF-8";
      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;
    };
    nixosModules.graphical = {
      imports = [ self.nixosModules.common ];
      home-manager.users.${config.people.myself} = {
        imports = [ self.homeModules.graphical ];
        home.packages = with pkgs; [
          bitwarden
          brave-browser
          godot
          protonvpn-gui
          android-studio
        ];
      };
      services.xserver = {
        enable = true;
        layout = "us";
        displayManager.sddm.enable = true;
        desktopManager.plasma5.enable = true;
      };
      fonts.fonts = with pkgs; [ meslo-lgs-nf ];
      sound.enable = true;
      hardware.pulseaudio.enable = true;
      users.users.${config.people.myself}.extraGroups = [ "networkmanager" ];
    };
  };
}
