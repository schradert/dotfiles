{
  dotfiles.home-manager = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (pkgs) fetchFromGitHub;
  in {
    config = lib.mkIf config.programs.zsh.enable {
      home.packages = [pkgs.meslo-lgs-nf];
      programs.zsh = {
        autosuggestion.enable = true;
        syntaxHighlighting.enable = true;
        enableVteIntegration = true;
        autocd = true;
        history.expireDuplicatesFirst = true;
        history.extended = true;
        initExtra = "fpath+=($ZSH/custom/plugins/zsh-completions/src)";
        localVariables.ZSH_AUTOSUGGEST_STRATEGY = ["history" "completion"];
        plugins = [
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
  };
}
