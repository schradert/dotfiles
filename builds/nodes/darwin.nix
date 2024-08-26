{
  config,
  inputs,
  nix,
  ...
}:
with nix; let
  inherit (config.dotfiles) domain;
  darwin = config.canivete.deploy.darwin.nodes.morgenmuffel.profiles.system.raw;
in {
  flake.overlays.gke-gcloud-auth-plugin = inputs.gke-gcloud-auth-plugin-flake.overlays.default;
  canivete.deploy.darwin.nodes.morgenmuffel = {
    target.sshOptions = ["ProxyJump=${domain}"];
    profiles.system.module = {
      dotfiles.graphical.enable = true;
      homebrew.enable = true;
      homebrew.brews = ["libtool" "vfkit"];
      homebrew.casks = [
        "clickup"
        # "dracula-wallpaper"
        "gitbutler"
        "google-drive"
        "lulu"
        "teamviewer"
        "zotero"
      ];
      homebrew.taps = [
        "cfergeau/crc"
        # "dracula/install"
      ];
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
    home.tristan = {
      config,
      lib,
      pkgs,
      ...
    }: {
      imports = toList {
        options.dotfiles = darwin.options.dotfiles;
        config.dotfiles = darwin.config.dotfiles;
      };
      dotfiles.graphical.enable = true;
      dotfiles.profile = "work";
      dotfiles.zsh.initExtraLines = nix.toList ''
        fixaudio() {
          sudo rm /Library/Preferences/Audio/com.apple.audio.DeviceSettings.plist
          sudo rm /Library/Preferences/Audio/com.apple.audio.SystemSettings.plist
          sudo killall coreaudiod
        }
      '';
      # TODO remove all of the extra logging (why isn't /dev/null working on relevant commands?)
      home.activation.prepareFutoffo = let
        gcloud = getExe pkgs.google-cloud-sdk;
      in
        lib.hm.dag.entryAfter ["linkGeneration"] ''
          chmod +x ${config.home.shellAliases.futoffo}
          if [[ -z $(${gcloud} auth list --filter active | grep '@climaxfoods.com' | ${pkgs.gawk}/bin/awk '{print $NF}' 2> /dev/null) ]]; then
             ${gcloud} auth login
          fi
          if [[ ! $(grep -q gcloud "$HOME/.docker/config.json" &> /dev/null) ]]; then
             ${gcloud} auth configure-docker
          fi
        '';
      home.packages = with pkgs; [google-cloud-sdk gke-gcloud-auth-plugin pngpaste python312 raycast];
      home.shellAliases.futoffo = "\"${config.home.homeDirectory}/Google Drive/Shared drives/software/futoffo/start_docker.command\"";
      home.stateVersion = "23.05";
      launchd.agents = let
        config.RunAtLoad = true;
        config.KeepAlive.Crashed = true;
      in {
        bitwarden.enable = true;
        bitwarden.config = config // {Program = "/Applications/Bitwarden.app/Contents/MacOS/Bitwarden";};
        brave.enable = true;
        brave.config = config // {Program = "/Applications/Brave Browser.app/Contents/MacOS/Brave Browser";};
        clickup.enable = true;
        clickup.config = config // {Program = "/Applications/ClickUp.app/Contents/MacOS/ClickUp";};
        gdrive.enable = true;
        gdrive.config = config // {Program = "/Applications/Google Drive.app/Contents/MacOS/Google Drive";};
        lulu.enable = true;
        lulu.config = config // {Program = "/Applications/LuLu.app/Contents/MacOS/LuLu";};
        protonvpn.enable = true;
        protonvpn.config = config // {Program = "/Applications/ProtonVPN.app/Contents/MacOS/ProtonVPN";};
        raycast.enable = true;
        raycast.config = config // {Program = "${pkgs.raycast}/Applications/Raycast.app/Contents/MacOS/Raycast";};
        wezterm.enable = true;
        wezterm.config = config // {Program = "${pkgs.wezterm}/Applications/WezTerm.app/Contents/MacOS/WezTerm";};
      };
      programs.zsh.oh-my-zsh.plugins = ["brew" "gcloud"];
    };
  };
}
