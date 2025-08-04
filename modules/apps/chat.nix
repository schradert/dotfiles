{
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
  dotfiles.nixos = {
    config,
    lib,
    ...
  }: {
    config = lib.mkIf config.dotfiles.profiles.client.enable {
      dotfiles.nixpkgs.config.allowUnfreePackages = ["discord" "slack" "beeper"];
      nixpkgs.overlays = [
        (_: prev: {
          zulip-term = prev.zulip-term.overridePythonAttrs (_: {
            disabledTests = [
              "test_main_help"
              "test_soup2markup" # link_userupload, link_api, preview-twitter
            ];
          });
        })
      ];
    };
  };
  dotfiles.home-manager = {
    config,
    lib,
    pkgs,
    ...
  }: {
    config = lib.mkIf config.dotfiles.profiles.client.enable {
      programs.doom-emacs = {
        extraBinPackages = [pkgs.gnutls];
        tangle.init.app.irc = true;
        # TODO add more channels
        # TODO bitwarden integration to fetch passwords
        # NOTE this would mean :sasl-username (+pass-get-user "irc/libera.chat") :sasl-password (+pass-get-secret "irc/libera.chat")
        # TODO how can I obscure my user and nicknames?
        tangle.config = ''
          (after! circe
            (defun fetch-password (&rest params)
              (require 'auth-source)
              (if-let* ((match (car (apply #'auth-source-search params)))
                        (secret (plist-get match :secret)))
                  (if (functionp secret)
                      (funcall secret)
                    secret)
                (user-error "Password not found for %S" params)))
            (set-irc-server! "irc.libera.chat"
                             '(:tls t
                               :port 6697
                               :nick "gobbledigook"
                               :sasl-password
                               (lambda (server)
                                 (fetch-password :user "tristan" :host "irc.libera.chat"))
                               :channels ("#emacs"))))
        '';
      };
      home.packages = with pkgs;
        lib.mkMerge [
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
            # TODO zulip-desktop
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
  };
}
