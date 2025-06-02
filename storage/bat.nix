{
  dotfiles.home-manager = {
    programs.bat = {
      enable = true;
      config.theme = "Dracula";
      # TODO why are these broken? file doesn't say anything about that
      # extraPackages = with pkgs.bat-extras; [prettybat batwatch batpipe batman batgrep batdiff];
      # TODO themes (how can it automatically choose by the wallpaper or my theme switcher?)
      # TODO syntaxes
    };
  };
}
