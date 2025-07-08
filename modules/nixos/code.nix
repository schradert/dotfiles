{
  dotfiles.nixos = {
    config,
    lib,
    ...
  }: {
    options.dotfiles.profiles.client.code.enable = lib.mkEnableOption "coding tools";
    config = lib.mkIf config.dotfiles.profiles.client.code.enable {
      assertions = lib.toList {
        assertion = config.dotfiles.profiles.client.enable;
        message = "Code is for clients";
      };
      home-manager.sharedModules = [
        ({pkgs, ...}: {
          programs = {
            emacs.enable = true;
            direnv.enable = true;
            gh.enable = true;
            git.enable = true;
            git.lfs.enable = true;
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
