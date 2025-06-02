{
  flake.overlays.media = _: prev: {
    # replace youtube-dl everywhere
    yt-dlp = prev.yt-dlp.override {withAlias = true;};
  };
  dotfiles.home-manager = {
    lib,
    pkgs,
    ...
  }: {
    dotfiles.programs.feh.enable = true;
    home.packages = with pkgs;
      lib.mkMerge [
        [
          aria2
          invidtui
          manga-tui
          webtorrent_desktop
          ytfzf
          # TODO nodePackages.webtorrent-cli
        ]
        (lib.mkIf stdenv.hostPlatform.isLinux [
          koreader
          venera
        ])
      ];
    programs.feh = {
      enable = true;
      keybindings = {
        prev_img = ["h" "Left"];
        next_img = ["l" "Right"];
        zoom_in = ["j" "Down"];
        zoom_out = ["k" "Up"];
      };
      themes = {
        booth = ["--full-screen" "--hide-pointer" "--slideshow-delay" "20"];
        feh = ["--image-bg" "black"];
        imagemap = ["--quiet" "--recursive" "--verbose" "--thumb-width" "40" "--thumb-height" "30" "--index-info" "%n\\n%wx%h"];
        present = ["--full-screen" "--sort" "name" "--hide-pointer"];
        webcam = ["--multiwindow" "--reload" "20"];
      };
    };
    programs.imv.settings.aliases = {
      h = "prev 1";
      l = "next 1";
      j = "zoom 10%";
      k = "zoom -10%";
      z = "zoom actual";
      _ = "flip vertical";
      "|" = "flip horizontal";
      w = "pan 0 -100";
      a = "pan -100 0";
      s = "pan 0 100";
      d = "pan 100 0";
      o = "overlay";
    };
    programs.yt-dlp.enable = true;
  };
}
