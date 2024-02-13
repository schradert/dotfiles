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
  };
}
