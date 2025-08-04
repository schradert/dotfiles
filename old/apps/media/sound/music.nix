{
  flake.overlays.ytui-music = final: prev: {
    ytui-music = prev.ytui-music.override {youtube-dl = final.yt-dlp;};
  };
  canivete.pkgs.allowUnfree = ["spotify"];
  # TODO choose a music player!!! (mpd)
  # TODO expose mpc to emacs
  dotfiles.home-manager = {
    canivete,
    config,
    lib,
    pkgs,
    ...
  }: {
    config = lib.mkIf config.dotfiles.profiles.client.enable {
      home.packages = with pkgs;
        lib.mkMerge [
          [spotube youtube-tui ytui-music]
          (canivete.mkUnless config.programs.spicetify.enable [spotify spotify-player])
          (lib.mkIf stdenv.hostPlatform.isLinux [scope-tui])
        ];
      programs.cava.enable = true;
      programs.doom-emacs.tangle.init.app.emms = true;
    };
  };
}
