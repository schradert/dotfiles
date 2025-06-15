{
  dotfiles.nixos = {config, lib, ...}: {
    options.dotfiles.client.code.enable = lib.mkEnableOption "coding tools";
    config = lib.mkIf config.dotfiles.client.code.enable {
      home-manager.sharedModules = [
        ({pkgs, ...}: {
          programs = {
            emacs.enable = true;
            direnv.enable = true;
            gh.enable = true;
            git.enable = true;
            navi.enable = true;
            wezterm.enable = true;
            vscode = {
              enable = true;
              package = pkgs.vscodium;
              profiles.default = {
                enableExtensionUpdateCheck = false;
                extensions = [pkgs.vscode-extensions.jnoortheen.nix-ide];
                userSettings = {
                  "editor.guides.bracketPairs" = true;
                  "editor.insertSpaces" = true;
                  "editor.tabSize" = 4;
                  "editor.inlineSuggest.enabled" = true;
                };
              };
            };
            zed-editor = {
              enable = true;
              extensions = ["dracula" "nix"];
              extraPackages = [pkgs.nixd];
              installRemoteServer = true;
              userSettings.telemetry.metrics = false;
            };
          };
        })
      ];
    };
  };
}
