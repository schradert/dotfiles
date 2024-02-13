{inputs, nix, withSystem, ...}: with nix; {
  flake.darwinConfigurations.morgenmuffel = withSystem (head (import inputs.systems-darwin)) ({pkgs, system, ...}: inputs.nix-darwin.lib.darwinSystem {
    inherit pkgs system;
    specialArgs = inputs.self.nixos-flake.lib.specialArgsFor.darwin;
    modules = builtins.attrValues inputs.self.systemModules ++ toList {
      environment.systemPackages = with pkgs; [pngpaste raycast];
      homebrew.enable = true;
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
    legacyPackages.homeConfigurations.tristan = inputs.self.nixos-flake.lib.mkHomeConfiguration pkgs {
      imports = attrValues inputs.self.homeModules;
      dotfiles.graphical.enable = true;
      dotfiles.hostname = "morgenmuffel";
      programs.emacs.enable = true;
      programs.zsh.oh-my-zsh.plugins = ["brew" "gcloud"];
      home.packages = with pkgs; [google-cloud-sdk gke-gcloud-auth-plugin];
    };
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
    });
  };
}
