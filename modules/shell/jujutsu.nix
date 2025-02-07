{
  flake.overlays.jujutsu = _: prev: {
    lazyjj = prev.lazyjj.overrideAttrs (_: {
      checkFlags = [
        # TODO follow https://github.com/NixOS/nixpkgs/issues/370890
        "--skip=commander::bookmarks::tests::get_bookmark_show"
        "--skip=commander::files::tests::get_file_diff"
        "--skip=commander::log::tests::get_commit_show"
      ];
    });
  };
  canivete.deploy.system.homeModules.jujutsu = {
    config,
    pkgs,
    ...
  }: let
    inherit (config.programs.git) extraConfig userEmail userName;
  in {
    home.packages = with pkgs; [gg-jj jjui lazyjj watchman];
    programs.jujutsu = {
      enable = true;
      ediff = true;
      settings = {
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
