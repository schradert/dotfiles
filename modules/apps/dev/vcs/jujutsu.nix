{
  dotfiles.home-manager = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (config.programs.git) extraConfig userEmail userName;
  in {
    config = lib.mkIf config.dotfiles.profiles.client.workstation.enable {
      home.packages = with pkgs; [gg-jj jjui lazyjj watchman];
      programs.jujutsu.enable = true;
      programs.jujutsu.settings = {
        core.fsmonitor = "watchman";
        signing = {
          backend = "ssh";
          backends.ssh.allowed-signers = extraConfig.gpg.ssh.allowedSignersFile;
          backends.ssh.program = extraConfig.gpg.ssh.program;
          key = extraConfig.user.signingKey;
          sign-all = true;
        };
        ui.diff.format = "git";
        ui.pager = "delta";
        user.email = userEmail;
        user.name = userName;
      };
    };
  };
}
