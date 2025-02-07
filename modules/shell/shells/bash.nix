{
  # TODO variables and options
  canivete.deploy.system.homeModules.bash = {
    config,
    pkgs,
    ...
  }: {
    dotfiles.programs.emacs.dependencies = with pkgs;
      lib.mkMerge [
        [bash-language-server shellcheck]
        (lib.mkIf stdenv.hostPlatform.isLinux [bashdb])
      ];
    programs.bash.historyFile = "${config.xdg.stateHome}/bash/history";
  };
}
