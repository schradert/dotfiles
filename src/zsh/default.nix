{
  flake.homeModules.zsh = {
    config,
    lib,
    nix,
    pkgs,
    ...
  }:
    with nix; {
      options.programs.zsh.initExtraLines = mkOption {
        type = listOf str;
        default = [];
        description = mdDoc "List implementation of programs.zsh.initExtra to allow merging";
      };
      config.programs.zsh = {
        enable = true;
        enableAutosuggestions = true;
        syntaxHighlighting.enable = true;
        enableVteIntegration = true;
        autocd = true;
        history.expireDuplicatesFirst = true;
        history.extended = true;
        # TODO trim leading tabs
        initExtra = concatMapStringsSep "\n" (x: x) config.programs.zsh.initExtraLines;
        initExtraLines = with config.programs;
          toList ''
            prompt_nix_shell_setup
            # set descriptions format to enable group support
            zstyle ':completion:*:descriptions' format '[%d]'
            # set list-colors to enable filename colorizing
            zstyle ':completion:*' list-colors $LS_COLORS  # ''${(s.:.)LS_COLORS}
            fpath+=($ZSH/custom/plugins/zsh-completions/src)
            ${optionalString fzf.enable ''
              bindkey '^R' fzf-history-widget
              # switch group using `,` and `.`
              zstyle ':fzf-tab:*' switch-group ',' '.'
              ${optionalString eza.enable ''
                # preview directory's content with exa when completing cd
                zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
              ''}
            ''}
          '';
        localVariables = {
          YSU_MESSAGE_POSITION = "after";
          YSU_MODE = "ALL";
          YSU_HARDCORE = 1;
          ZSH_AUTOSUGGEST_STRATEGY = ["history" "completion"];
          DIRENV_WARN_TIMEOUT = "10s";
        };
        oh-my-zsh.enable = true;
        oh-my-zsh.plugins = with config;
          flatten [
            "aliases"
            "battery"
            "colored-man-pages"
            "common-aliases"
            "cp"
            "dirhistory"
            "docker"
            "docker-compose"
            "ripgrep"
            "rsync"
            (optionals programs.gh.enable ["gh"])
            (optionals programs.fzf.enable ["fzf"])
            (optionals programs.git.enable ["git git-auto-fetch"])
            (optionals programs.tmux.enable ["tmux"])
            (optionals programs.k9s.enable ["helm" "kubectl"])
            (optionals programs.k9s.enable ["helm" "kubectl"])
          ];
        plugins = with pkgs; [
          {
            name = "powerlevel10k";
            src = zsh-powerlevel10k;
            file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
          }
          {
            name = "powerlevel10k-config";
            src = cleanSource ./.;
            file = ".p10k.zsh";
          }
          {
            name = "fzf-tab";
            src = fetchFromGitHub {
              owner = "Aloxaf";
              repo = "fzf-tab";
              rev = "master";
              sha256 = "ilUavAIWmLiMh2PumtErMCpOcR71ZMlQkKhVOTDdHZw=";
            };
          }
          {
            name = "fast-syntax-highlighting";
            src = fetchFromGitHub {
              owner = "zdharma-continuum";
              repo = "fast-syntax-highlighting";
              rev = "v1.55";
              sha256 = "DWVFBoICroKaKgByLmDEo4O+xo6eA8YO792g8t8R7kA=";
            };
          }
          {
            name = "zsh-256color";
            src = fetchFromGitHub {
              owner = "chrissicool";
              repo = "zsh-256color";
              rev = "master";
              sha256 = "P/pbpDJmsMSZkNi5GjVTDy7R+OxaIVZhb/bEnYQlaLo=";
            };
          }
          {
            name = "git-extra-commands";
            src = fetchFromGitHub {
              owner = "unixorn";
              repo = "git-extra-commands";
              rev = "05083c4ed2f0f5e253714e340625adaf8d51e2eb";
              sha256 = "OQ1LH0XNQgNF6DEUO4i4zNls95Y2ZVngnN2AUMQ65MU=";
            };
          }
          {
            name = "you-should-use";
            src = fetchFromGitHub {
              owner = "MichaelAquilina";
              repo = "zsh-you-should-use";
              rev = "1.7.3";
              sha256 = "/uVFyplnlg9mETMi7myIndO6IG7Wr9M7xDFfY1pG5Lc=";
            };
          }
          {
            name = "zsh-aliases-exa";
            src = fetchFromGitHub {
              owner = "DarrinTisdale";
              repo = "zsh-aliases-exa";
              rev = "master";
              sha256 = "31od2U/8MtIYh801eBdOvubzON5GpMM/2kWjkGXguAE=";
            };
          }
          {
            name = "zsh-autosuggestions";
            src = fetchFromGitHub {
              owner = "zsh-users";
              repo = "zsh-autosuggestions";
              rev = "v0.7.0";
              sha256 = "KLUYpUu4DHRumQZ3w59m9aTW6TBKMCXl2UcKi4uMd7w=";
            };
          }
          {
            name = "zsh-completions";
            src = fetchFromGitHub {
              owner = "zsh-users";
              repo = "zsh-completions";
              rev = "0.34.0";
              sha256 = "qSobM4PRXjfsvoXY6ENqJGI9NEAaFFzlij6MPeTfT0o=";
            };
          }
          {
            name = "nix-zsh-completions";
            src = fetchFromGitHub {
              owner = "spwhitt";
              repo = "nix-zsh-completions";
              rev = "0.4.4";
              sha256 = "Djs1oOnzeVAUMrZObNLZ8/5zD7DjW3YK42SWpD2FPNk=";
            };
          }
        ];
      };
    };
}
