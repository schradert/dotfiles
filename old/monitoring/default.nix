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
          lazyjournal
          lnav
          lsof
          procps
          systemctl-tui
          trippy
          zenith
        ]
        (lib.mkIf stdenv.hostPlatform.isLinux [
          kmon
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
