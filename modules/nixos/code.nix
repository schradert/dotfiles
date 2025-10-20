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
          home.packages = [pkgs.devenv];
          dotfiles.editor = "emacs";
          dotfiles.programs = {
            agda.enable = true;
            godot.enable = true;
            go.enable = true;
            graphql.enable = true;
            graphviz.enable = true;
            haskell.enable = true;
            idris.enable = true;
            java.enable = true;
            javascript.enable = true;
            julia.enable = true;
            kotlin.enable = true;
            latex.enable = true;
            lua.enable = true;
            pandoc.enable = true;
            python.enable = true;
            rust.enable = true;
            zig.enable = true;
          };
          programs = {
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
