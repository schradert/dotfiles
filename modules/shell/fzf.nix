{
  canivete.deploy.system.homeModules.fzf = {
    config,
    lib,
    pkgs,
    ...
  }: {
    programs.fzf.enable = true;
    programs.zsh.initExtra = ''
      bindkey '^R' fzf-history-widget
      # switch group using `,` and `.`
      zstyle ':fzf-tab:*' switch-group ',' '.'
      ${lib.optionalString config.programs.eza.enable ''
        # preview directory's content with exa when completing cd
        zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
      ''}
      try() {
          export FZF_DEFAULT_COMMAND=echo
          fzf -q "$*" --preview-window=up:99% --preview="eval {q}"
      }
    '';
    programs.zsh.oh-my-zsh.plugins = ["fzf"];
    programs.zsh.plugins = lib.toList {
      name = "fzf-tab";
      src = pkgs.fetchFromGitHub {
        owner = "Aloxaf";
        repo = "fzf-tab";
        rev = "master";
        sha256 = "ilUavAIWmLiMh2PumtErMCpOcR71ZMlQkKhVOTDdHZw=";
      };
    };
  };
}
