{
  dotfiles.home-manager = {
    lib,
    pkgs,
    ...
  }: {
    home.packages = with pkgs;
      lib.mkMerge [
        # NOTE dependency "libappindicator-gtk3" not available on Darwin
        (lib.mkIf stdenv.hostPlatform.isLinux [udiskie])
        [
          caligula
          docfd
          duf
          fd
          file
          localsend
          ranger
          tran
          tree
          unzip
          xplr
        ]
      ];
    programs = {
      dircolors.enable = true;
      eza.enable = true;
      zoxide.enable = true;
    };
  };
}
