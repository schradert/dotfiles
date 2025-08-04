{
  dotfiles.home-manager = {
    config,
    lib,
    pkgs,
    ...
  }: {
    config = lib.mkIf config.dotfiles.profiles.client.workstation.enable {
      editorconfig.enable = true;
      programs.doom-emacs.tangle.init.tools.editorconfig = true;
      programs.doom-emacs.extraBinPackages = [pkgs.editorconfig-core-c];
    };
  };
}
