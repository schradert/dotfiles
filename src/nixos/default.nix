{
  self,
  config,
  ...
}:
let flakeConfig = config;
    in
{
  flake = {
    nixosModules.common = {pkgs, config, lib, ...}: {
      imports = [
        self.nixosModules.home-manager
      ];
      users.users.${flakeConfig.people.me} = {
        isNormalUser = true;
        home = "/home/${flakeConfig.people.me}";
        description = flakeConfig.people.my.name;
        extraGroups = ["wheel" "tty"];
        shell = pkgs.zsh;
        openssh.authorizedKeys.keys = lib.attrsets.catAttrs "public" (builtins.attrValues flakeConfig.people.my.sshKeys);
      };
      home-manager.users.${flakeConfig.people.me} = {
        imports = [self.homeModules.common];
        home.packages = with pkgs; [nethogs protonvpn-cli];
      };
      environment.pathsToLink = ["/share/zsh"];
      environment.shells = [pkgs.zsh];
      home-manager.useUserPackages = true;
      home-manager.useGlobalPkgs = true;
      users.users.root.openssh.authorizedKeys.keys = lib.attrsets.catAttrs "public" (builtins.attrValues flakeConfig.people.my.sshKeys);
      users.mutableUsers = true;
      services.openssh.enable = true;
      system.stateVersion = "22.11";
      security.polkit.enable = true;
      security.pam.enableSSHAgentAuth = true;
      virtualisation.podman = {
        enable = true;
        dockerSocket.enable = true;
        defaultNetwork.settings.dns_enable = true;
      };
      time.timeZone = "America/Los_Angeles";
      i18n.defaultLocale = "en_US.UTF-8";
      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;
      programs.zsh.enable = true;
    };
    nixosModules.headless = {
      imports = [self.nixosModules.common];
      home-manager.users.${flakeConfig.people.me}.imports = [self.homeModules.headless];
    };
    nixosModules.graphical = {
      pkgs,
      lib,
      ...
    }: {
      imports = [self.nixosModules.common];
      home-manager.users.${flakeConfig.people.me} = {
        imports = [self.homeModules.linux-graphical];
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
      fonts.fonts = with pkgs; [meslo-lgs-nf];
      sound.enable = true;
      hardware.pulseaudio.enable = true;
      users.users.${flakeConfig.people.me}.extraGroups = ["networkmanager"];
    };
  };
}
