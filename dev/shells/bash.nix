{
  # TODO variables and options
  dotfiles.home-manager = {
    config,
    pkgs,
    ...
  }: {
    dotfiles.programs.emacs.dependencies = with pkgs;
      lib.mkMerge [
        [bash-language-server shellcheck]
        (lib.mkIf stdenv.hostPlatform.isLinux [bashdb])
      ];
    programs.bash.enable = true;
    programs.bash.historyFile = "${config.xdg.stateHome}/bash/history";
  };
}
