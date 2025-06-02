{
  dotfiles.home-manager = {config, ...}: {
    dotfiles.editor = "hx";
    dotfiles.programs = {
      git.enable = true;
      nix-inspect.enable = true;
      zsh.enable = true;
    };
    home.sessionVariables = let
      inherit (config) xdg;
    in {
      XDG_CACHE_HOME = xdg.cacheHome;
      XDG_CONFIG_HOME = xdg.configHome;
      XDG_DATA_HOME = xdg.dataHome;
      XDG_STATE_HOME = xdg.stateHome;
      # TODO how can I get the user UID?
      XDG_RUNTIME_DIR = "/run/user/1000";
    };
    fonts.fontconfig.enable = true;
    programs = {
      helix.enable = true;
      jq.enable = true;
      # TODO why is it panicking when I try to call it from `nix run`?
      # nix-your-shell.enable = true;
      starship.enable = true;
      zoxide.enable = true;
    };
  };
}
