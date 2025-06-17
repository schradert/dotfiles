{
  canivete.pkgs.allowUnfree = ["discord" "slack" "beeper"];
  dotfiles.darwin = {
    config,
    lib,
    ...
  }: {
    homebrew.casks = lib.mkIf config.dotfiles.profiles.client.enable [
      "beeper"
      "element"
      "legcord"
      "quiet"
      "session"
      "signal"
    ];
  };
  dotfiles.home-manager = {
    lib,
    pkgs,
    ...
  }: {
    dotfiles.programs.emacs.orgFiles = [./irc.org];
    home.packages = with pkgs;
      mkMerge [
        [
          discord
          nchat
          profanity
          scli
          signal-cli
          slack
          toot
          tuisky
          twitch-tui
          zulip-term
        ]
        (lib.mkIf stdenv.hostPlatform.isLinux [
          beeper
          element-desktop
          quiet
          session-desktop
          signal-desktop
          simplex-chat-desktop

          # alternative discord
          discordo
          legcord
          webcord
        ])
      ];
  };
}
