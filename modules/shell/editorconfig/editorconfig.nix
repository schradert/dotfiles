{
  canivete.deploy.system.homeModules.editorconfig = {pkgs, ...}: {
    editorconfig.enable = true;
    # TODO set default editorconfig settings
    dotfiles.programs.emacs = {
      dependencies = [pkgs.editorconfig-core-c];
      orgFiles = [./editorconfig.org];
    };
  };
}
