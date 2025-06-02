{
  canivete.pkgs.allowUnfree = ["raycast"];
  canivete.deploy.nodes.morgenmuffel = {
    canivete.os = "macos";
    profiles.system.canivete.configuration = {
      dotfiles.workstation.enable = true;
      homebrew = {
        enable = true;
        # TODO why did I add these?
        brews = ["libtool" "vfkit"];
        casks = ["zotero"];
        taps = ["cfergeau/crc"];
      };
      # TODO relocate sudo
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
      system.stateVersion = 4;
    };
    profiles.tristan.canivete.type = "home-manager";
    profiles.tristan.canivete.configuration = {
      node,
      pkgs,
      ...
    }: let
      inherit (node.config.profiles) system;
      module.options.dotfiles = system.options.dotfiles;
      module.config.dotfiles = system.config.dotfiles;
    in {
      imports = [module];
      home.packages = [pkgs.raycast];
      home.stateVersion = "23.05";
      launchd.agents.raycast = {
        enable = true;
        config.KeepAlive.Crashed = true;
        config.Program = "${pkgs.raycast}/Applications/Raycast.app/Contents/MacOS/Raycast";
        config.RunAtLoad = true;
      };
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
