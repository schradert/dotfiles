{
  config,
  inputs,
  ...
}: let
  inherit (config.dotfiles) domain;
  darwin = config.canivete.deploy.darwin.nodes.morgenmuffel.profiles.system.raw;
in {
  flake.deploy.nodes.morgenmuffel = {
    hostname = "morgenmuffel";
    profiles.system = {
      user = "tristan";
      path = inputs.deploy-rs.lib.aarch64-darwin.activate.nixos inputs.self.darwinConfigurations.morgenmuffel;
    };
  };
  # flake.checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks inputs.self.deploy) inputs.deploy-rs.lib;

  # TODO https://github.com/exelban/stats
  # TODO https://github.com/koekeishiya/yabai vs https://github.com/nikitabobko/AeroSpace
  # TODO https://github.com/jordanbaird/Ice
  # TODO https://github.com/lwouis/alt-tab-macos
  canivete.deploy.darwin.nodes.morgenmuffel = {
    target.sshOptions = ["ProxyJump=${domain}"];
    profiles.system.module = {
      dotfiles.workstation.enable = true;
      homebrew = {
        enable = true;
        brews = ["libtool" "vfkit"];
        casks = ["zotero"];
        taps = ["cfergeau/crc"];
      };
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
    home.tristan = {pkgs, ...}: {
      imports = [
        {
          options.dotfiles = darwin.options.dotfiles;
          config.dotfiles = darwin.config.dotfiles;
        }
      ];
      home.packages = [pkgs.raycast];
      home.stateVersion = "23.05";
      launchd.agents.raycast = {
        enable = true;
        config.KeepAlive.Crashed = true;
        config.Program = "${pkgs.raycast}/Applications/Raycast.app/Contents/MacOS/Raycast";
        config.RunAtLoad = true;
      };
      programs.zsh.initExtra = ''
        fixaudio() {
          sudo rm /Library/Preferences/Audio/com.apple.audio.DeviceSettings.plist
          sudo rm /Library/Preferences/Audio/com.apple.audio.SystemSettings.plist
          sudo killall coreaudiod
        }
      '';
      programs.zsh.oh-my-zsh.plugins = ["brew"];
    };
  };
}
