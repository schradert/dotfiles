{
  dotfiles.nixos = {
    config,
    lib,
    ...
  }: {
    dotfiles.nixpkgs.config.allowUnfreePackages = lib.mkIf config.dotfiles.profiles.client.workstation.enable ["vscode-extension-visualjj-visualjj"];
  };
  dotfiles.home-manager = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (config.programs.git) extraConfig userEmail userName;
    jj = lib.getExe config.programs.jujutsu.package;
  in {
    config = lib.mkIf config.dotfiles.profiles.client.workstation.enable {
      home.packages = with pkgs; [gg-jj jjui jj-fzf lazyjj watchman];
      dotfiles.programs.nushell.sources.jj = "${jj} util completion nushell";
      dotfiles.programs.xonsh.interactiveExtra = "source-bash $(${jj} util completion)";
      programs = {
        bash.initExtra = "source <(COMPLETE=bash ${jj})";
        zsh.initContent = "source <(COMPLETE=zsh ${jj})";

        doom-emacs.extraPackages = e: [e.vc-jj e.jjdescription];
        vim.plugins = [pkgs.vimPlugins.vim-jjdescription];
        vscode.profiles.default.extensions = [pkgs.vscode-extensions.visualjj.visualjj];
        jujutsu.enable = true;
        jujutsu.settings = {
          core.fsmonitor = "watchman";
          signing = {
            backend = "ssh";
            backends.ssh.allowed-signers = extraConfig.gpg.ssh.allowedSignersFile;
            backends.ssh.program = extraConfig.gpg.ssh.program;
            behavior = "own";
            key = extraConfig.user.signingKey;
          };
          ui.conflict-marker-style = "git";
          ui.diff-formatter = ":git";
          ui.pager = "delta";
          user.email = userEmail;
          user.name = userName;
        };
      };
    };
  };
}
