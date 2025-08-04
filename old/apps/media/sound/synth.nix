{
  dotfiles = {
    darwin = {
      config,
      lib,
      ...
    }: {
      homebrew.casks = lib.mkIf config.dotfiles.profiles.client.workstation.enable ["supercollider"];
    };
    home-manager = {
      config,
      lib,
      pkgs,
      ...
    }: {
      config = lib.mkIf config.dotfiles.profiles.client.workstation.enable {
        programs.doom-emacs.tangle.packages = "(package! glicol-mode :recipe (:host github :repo \"khtdr/glicol-mode\") :pin \"62a86aa2a641e633d845687ae0c4589179a66cb3\")";
        home.packages = with pkgs;
          lib.mkMerge [
            [ardour glicol-cli faust upiano]
            (lib.mkIf stdenv.hostPlatform.isLinux [supercollider-with-sc3-plugins])
          ];
      };
    };
  };
}
