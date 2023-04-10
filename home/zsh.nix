{ pkgs }: {
  enable = true;
  enableAutosuggestions = true;
  enableSyntaxHighlighting = true;
  enableVteIntegration = true;
  autocd = true;
  history = {
    expireDuplicatesFirst = true;
    extended = true;
  };
  sessionVariables = {
    VISUAL = "vim";
    YSU_MESSAGE_POSITION = "after";
    YSU_MODE = "ALL";
    YSU_HARDCORE = 1;
  };
  initExtra = ''
    bindkey '^R' fzf-history-widget
    prompt_nix_shell_setup
  '';
  localVariables = {
    ZSH_AUTOSUGGEST_STRATEGY = [ "history" "completion" ];
  };
  oh-my-zsh = {
    enable = true;
    plugins = [
      "aliases"
      "colored-man-pages"
      "common-aliases"
      "cp"
      "dirhistory"
      "docker"
      "docker-compose"
      "fast-syntax-highlighting"
      "fzf"
      "fzf-tab"
      "gcloud"
      "gh"
      "git"
      "git-auto-fetch"
      "git-extra-commands"
      "nix-zsh-completions"
      "ripgrep"
      "rsync"
      "tmux"
      "vscode"
      "you-should-use"
      "zsh-aliases-exa"
      "zsh-autosuggestions"
      "zsh-256color"
    ];
  };
  plugins = [
    {
      name = "powerlevel10k";
      src = pkgs.zsh-powerlevel10k;
      file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
    }
    {
      name = "powerlevel10k-config";
      src = pkgs.lib.cleanSource ./p10k-config;
      file = ".p10k.zsh";
    }
    {
      name = "fzf-tab";
      src = pkgs.fetchFromGitHub {
        owner = "Aloxaf";
        repo = "fzf-tab";
        rev = "master";
        sha256 = "dPe5CLCAuuuLGRdRCt/nNruxMrP9f/oddRxERkgm1FE=";
      };
    }
    {
      name = "fast-syntax-highlighting";
      src = pkgs.fetchFromGitHub {
        owner = "zdharma-continuum";
        repo = "fast-syntax-highlighting";
        rev = "v1.55";
        sha256 = "DWVFBoICroKaKgByLmDEo4O+xo6eA8YO792g8t8R7kA=";
      };
    }
    {
      name = "zsh-256color";
      src = pkgs.fetchFromGitHub {
        owner = "chrissicool";
        repo = "zsh-256color";
        rev = "master";
        sha256 = "P/pbpDJmsMSZkNi5GjVTDy7R+OxaIVZhb/bEnYQlaLo=";
      };
    }
    {
      name = "git-extra-commands";
      src = pkgs.fetchFromGitHub {
        owner = "unixorn";
        repo = "git-extra-commands";
        rev = "main";
        sha256 = "cVuTcrDMustURC9IVtuYntZx79s7ekIogWtavu623Ts=";
      };
    }
    {
      name = "you-should-use";
      src = pkgs.fetchFromGitHub {
        owner = "MichaelAquilina";
        repo = "zsh-you-should-use";
        rev = "1.7.3";
        sha256 = "/uVFyplnlg9mETMi7myIndO6IG7Wr9M7xDFfY1pG5Lc=";
      };
    }
    {
      name = "zsh-aliases-exa";
      src = pkgs.fetchFromGitHub {
        owner = "DarrinTisdale";
        repo = "zsh-aliases-exa";
        rev = "master";
        sha256 = "h4Wu2bUTKH25O0QCy3sAD7w1Xot/nleeqmJLqBhU7Xc=";
      };
    }
    {
      name = "zsh-autosuggestions";
      src = pkgs.fetchFromGitHub {
        owner = "zsh-users";
        repo = "zsh-autosuggestions";
        rev = "v0.7.0";
        sha256 = "KLUYpUu4DHRumQZ3w59m9aTW6TBKMCXl2UcKi4uMd7w=";
      };
    }
    {
      name = "zsh-completions";
      src = pkgs.fetchFromGitHub {
        owner = "zsh-users";
        repo = "zsh-completions";
        rev = "0.34.0";
        sha256 = "qSobM4PRXjfsvoXY6ENqJGI9NEAaFFzlij6MPeTfT0o=";
      };
    }
    {
      name = "nix-zsh-completions";
      src = pkgs.fetchFromGitHub {
        owner = "spwhitt";
        repo = "nix-zsh-completions";
        rev = "0.4.4";
        sha256 = "Djs1oOnzeVAUMrZObNLZ8/5zD7DjW3YK42SWpD2FPNk=";
      };
    }
  ];

}
