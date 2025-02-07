{
  canivete.deploy.system.homeModules.java = {
    config,
    lib,
    pkgs,
    ...
  }: {
    options.dotfiles.programs.java.enable = lib.mkEnableOption "java";
    config = lib.mkIf config.dotfiles.programs.java.enable {
      programs.java.enable = true;
      programs.java.package = pkgs.jdk11;
      dotfiles.programs.emacs = {
        dependencies = [pkgs.jdt-language-server];
        orgFiles = [./java.org];
      };
    };
  };
}
