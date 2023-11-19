{ self, config, ... }:
{
  flake = {
    nixosModules.common = ({ pkgs, ... }: {
      imports = [
        self.nixosModules.home-manager
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
      };
      environment.pathsToLink = [ "/share/zsh" ];
      environment.shells = [ pkgs.zsh ];
      home-manager.useUserPackages = true;
      home-manager.useGlobalPkgs = true;
      users.users.root.openssh.authorizedKeys.keys = config.people.users.${config.people.myself}.sshKeys;
      users.mutableUsers = true;
      services.openssh.enable = true;
      system.stateVersion = "22.11";
      security.polkit.enable = true;
      security.pam.enableSSHAgentAuth = true;
      virtualisation.podman = { enable = true; dockerSocket.enable = true; defaultNetwork.settings.dns_enable = true; };
      time.timeZone = "America/Los_Angeles";
      i18n.defaultLocale = "en_US.UTF-8";
      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;
      programs.zsh.enable = true;
    });
    nixosModules.headless = {
      imports = [ self.nixosModules.common ];
      home-manager.users.${config.people.myself}.imports = [ self.homeModules.headless ];
    };
    nixosModules.graphical = ({ pkgs, lib, ... }: {
      imports = [ self.nixosModules.common ];
      home-manager.users.${config.people.myself} = {
        imports = [ self.homeModules.linux-graphical ];
        home.packages = with pkgs; [
          bitwarden
          brave
          godot
          protonvpn-gui
          android-studio
        ];
        # TODO (Tristan): why isn't this working?!
        # nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "android-studio-stable" ];
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
    });
  };
}
