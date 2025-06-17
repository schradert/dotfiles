{
  dotfiles.home-manager = {
    config,
    lib,
    pkgs,
    ...
  }: {
    config = lib.mkIf config.editorconfig.enable {
      # TODO set default editorconfig settings
      dotfiles.programs.emacs = {
        dependencies = [pkgs.editorconfig-core-c];
        orgFiles = [./editorconfig.org];
      };
    };
  };
}
