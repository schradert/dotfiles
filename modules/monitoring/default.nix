{
  dotfiles.home-manager = {
    lib,
    pkgs,
    ...
  }: {
    home.packages = with pkgs;
      lib.mkMerge [
        [
          bottom
          gping
          hwatch
          iftop
          lnav
          lsof
          procps
          trippy
          zenith
        ]
        (lib.mkIf stdenv.hostPlatform.isLinux [
          kmon
          lazyjournal
          systemctl-tui
          systeroid
        ])
      ];
    programs = {
      btop.enable = true;
      btop.settings.vim_keys = true;
      htop.enable = true;
    };
  };
}
