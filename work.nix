{
  inputs,
  nix,
  withSystem,
  ...
}:
with nix; {
  people.users.tristan.profiles.work.email = "tristan@climaxfoods.com";
  flake.darwinConfigurations.morgenmuffel = withSystem "aarch64-darwin" ({
    pkgs,
    system,
    ...
  }:
    inputs.nix-darwin.lib.darwinSystem {
      inherit pkgs system;
      specialArgs = inputs.self.nixos-flake.lib.specialArgsFor.darwin;
      modules =
        attrValues inputs.self.systemModules
        ++ toList {
          networking.hostName = "morgenmuffel";
          homebrew.enable = true;
          homebrew.brews = ["libtool"];
          homebrew.casks = [
            "android-studio"
            "anki"
            "bitwarden"
            "brave-browser"
            "clickup"
            "element"
            "godot"
            "google-drive"
            "lulu"
            "podman-desktop"
            "protonvpn"
            "session"
            "signal"
            "teamviewer"
            "zotero"
          ];
          nix.useDaemon = true;
          system.defaults.dock = {
            autohide = true;
            orientation = "left";
            static-only = true;
          };
          system.stateVersion = 4;
        };
    });
  flake.overlays.gke-gcloud-auth-plugin = inputs.gke-gcloud-auth-plugin-flake.overlays.default;
  perSystem = {pkgs, ...}: {
    legacyPackages.homeConfigurations.tristan = inputs.self.nixos-flake.lib.mkHomeConfiguration pkgs (home: {
      imports = attrValues inputs.self.homeModules;
      options.dotfiles.graphical.enable = mkEnableOption "graphical tools (i.e. not headless)";
      config = {
        dotfiles.graphical.enable = true;
        dotfiles.hostname = "morgenmuffel";
        programs.emacs.enable = true;
        programs.ssh.matchBlocks = mapAttrs (_:
          mergeAttrs {
            identityFile = "${home.config.home.homeDirectory}/.ssh/work";
            user = "terraform";
          }) {};
        programs.zsh.oh-my-zsh.plugins = ["brew" "gcloud"];
        # TODO remove all of the extra logging (why isn't /dev/null working on relevant commands?)
        home.activation.prepareFutoffo = let
          gcloud = getExe pkgs.google-cloud-sdk;
        in
          home.lib.hm.dag.entryAfter ["linkGeneration"] ''
            chmod +x ${home.config.home.shellAliases.futoffo}
            if [[ -z $(${gcloud} auth list --filter active | grep '@climaxfoods.com' | ${pkgs.gawk}/bin/awk '{print $NF}' 2> /dev/null) ]]; then
               ${gcloud} auth login
            fi
            if [[ ! $(grep -q gcloud "$HOME/.docker/config.json" &> /dev/null) ]]; then
               ${gcloud} auth configure-docker
            fi
          '';
        home.packages = with pkgs; [google-cloud-sdk gke-gcloud-auth-plugin pngpaste python312 raycast];
        home.shellAliases.futoffo = "\"${home.config.home.homeDirectory}/Google Drive/Shared drives/software/futoffo/start_docker.command\"";
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
          podman.enable = true;
          podman.config = config // {Program = "/Applications/Podman Desktop.app/Contents/MacOS/Podman Desktop";};
          protonvpn.enable = true;
          protonvpn.config = config // {Program = "/Applications/ProtonVPN.app/Contents/MacOS/ProtonVPN";};
          raycast.enable = true;
          raycast.config = config // {Program = "${pkgs.raycast}/Applications/Raycast.app/Contents/MacOS/Raycast";};
          wezterm.enable = true;
          wezterm.config = config // {Program = "${pkgs.wezterm}/Applications/WezTerm.app/Contents/MacOS/WezTerm";};
        };
      };
    });
  };
}
