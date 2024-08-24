{
  canivete.deploy.system.homeModules.fzf = {config, nix, pkgs, ...}: {
    dotfiles.zsh.initExtraLines = nix.toList ''
      bindkey '^R' fzf-history-widget
      # switch group using `,` and `.`
      zstyle ':fzf-tab:*' switch-group ',' '.'
      ${nix.optionalString config.programs.eza.enable ''
        # preview directory's content with exa when completing cd
        zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
      ''}
    '';
    programs.fzf.enable = true;
    programs.zsh.oh-my-zsh.plugins = ["fzf"];
    programs.zsh.plugins = nix.toList {
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
