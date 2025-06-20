{
  dotfiles = {
    darwin = {
      config,
      lib,
      ...
    }: {
      homebrew.casks = lib.mkIf config.dotfiles.workstation.enable ["supercollider"];
    };
    home-manager = {
      config,
      lib,
      pkgs,
      ...
    }: {
      config = lib.mkIf config.dotfiles.workstation.enable {
        home.packages = with pkgs;
          lib.mkMerge [
            [ardour glicol-cli faust upiano]
            (lib.mkIf stdenv.hostPlatform.isLinux [supercollider-with-sc3-plugins])
          ];
        dotfiles.programs.emacs.orgFiles = [./sound.org];
      };
    };
  };
}
