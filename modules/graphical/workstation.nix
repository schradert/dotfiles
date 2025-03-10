{
  canivete.deploy = {
    system.modules.workstation = {
      config,
      lib,
      ...
    }: {
      options.dotfiles.workstation.enable = lib.mkEnableOption "primary workstation configuration";
      config = lib.mkIf config.dotfiles.workstation.enable {
        dotfiles.containers = true;
        dotfiles.graphical.enable = true;
        dotfiles.graphical.sound.synth.enable = true;
        dotfiles.profiles.silly = true;
        dotfiles.profiles.chat.enable = true;
        dotfiles.programs.godot.enable = true;
      };
    };
    system.homeModules.workstation = {
      config,
      lib,
      pkgs,
      ...
    }: {
      config = lib.mkIf config.dotfiles.workstation.enable (lib.mkMerge [
        {
          dotfiles.email = true;
          dotfiles.graphical.sound.music.enable = true;
          dotfiles.graphical.wireless.enable = true;
          dotfiles.profiles = {
            ai.enable = true;
            databases = true;
            reading.enable = true;
          };
          dotfiles.programs = {
            adguardian.enable = true;
            agda.enable = true;
            direnv.enable = true;
            elvish.enable = true;
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
            wordnet.enable = true;
            xonsh.enable = true;
            zig.enable = true;
          };
          home.packages = [pkgs.tftui];
          programs = {
            nushell.enable = true;
          };
        }
        (lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
          programs.imv.enable = true;
          dotfiles.programs.obs-studio.enable = true;
        })
      ]);
    };
    nixos.modules.workstation = {
      config,
      lib,
      ...
    }: {
      config = lib.mkIf config.dotfiles.workstation.enable {
        dotfiles.graphical.sound.enable = true;
      };
    };
  };
}
