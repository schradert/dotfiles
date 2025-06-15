{
  dotfiles.nixos = {
    home-manager.sharedModules = [
      ({
        config,
        lib,
        pkgs,
        ...
      }: {
        options.dotfiles.programs.elvish.interactiveExtra = lib.mkOption {
          type = lib.types.lines;
          default = "";
        };
        options.dotfiles.programs.xonsh.interactiveExtra = lib.mkOption {
          type = lib.types.lines;
          default = "";
        };
        config = {
          home.packages = [pkgs.elvish];
          programs = {
            bash.enable = true;
            fish.enable = true;
            nushell.enable = true;
            zsh.enable = true;
          };
          xdg.configFile."elvish/rc.elv".source = pkgs.writeText "rc.elv" config.dotfiles.programs.elvish.interactiveExtra;
          xdg.configFile."xonsh/rc.xsh".source = pkgs.writeText "rc.xsh" ''
            if __xonsh__.env.get("XONSH_INTERACTIVE"):
                ${config.dotfiles.programs.xonsh.interactiveExtra}
          '';
        };
      })
    ];
    # I don't want to recreate this module in home-manager for now...
    programs.xonsh.enable = true;
  };
}
