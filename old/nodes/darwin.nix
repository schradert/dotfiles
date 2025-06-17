{
  dotfiles.darwin = {
    config,
    lib,
    ...
  }: {
    config = lib.mkMerge [
      {system.stateVersion = 4;}
      (lib.mkIf config.dotfiles.profiles.workstation.enable {
        homebrew.enable = true;
        security.pam.enableSudoTouchIdAuth = true;
        security.sudo.extraConfig = ''
          root ALL=(ALL) NOPASSWD: ALL
          %admin ALL=(ALL) NOPASSWD: ALL
        '';
        services.karabiner-elements.enable = true;
        system.defaults.dock = {
          autohide = true;
          orientation = "left";
          static-only = true;
        };
      })
    ];
  };
  dotfiles.home-manager = {
    config,
    lib,
    pkgs,
    ...
  }: {
    config = lib.mkIf (config.dotfiles.profiles.workstation.enable && pkgs.stdenv.hostPlatform.isDarwin) {
      programs.zsh.oh-my-zsh.plugins = ["brew"];
      # TODO does this actually work?!
      programs.zsh.initExtra = ''
        fixaudio() {
          sudo rm /Library/Preferences/Audio/com.apple.audio.DeviceSettings.plist
          sudo rm /Library/Preferences/Audio/com.apple.audio.SystemSettings.plist
          sudo killall coreaudiod
        }
      '';
    };
  };
}
