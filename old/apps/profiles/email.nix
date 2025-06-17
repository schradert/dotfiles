{
  dotfiles.home-manager = {
    config,
    flake,
    lib,
    pkgs,
    ...
  }: let
    inherit (flake.config.canivete.meta.people) users;
    inherit (lib) flip getExe mapAttrs mkIf mkMerge;
    inherit (pkgs) mu isync hydroxide stdenv;
    user = users.${config.home.username};
  in {
    config = mkIf config.dotfiles.workstation.enable (mkMerge [
      {
        home.packages = [mu mu.mu4e isync hydroxide];
        accounts.email.accounts = flip mapAttrs user.profiles (name: cfg: {
          # TODO alot contact completion
          # TODO can I use a shared mbsync config?
          # TODO activate msmtp and SMTP hydroxide server
          primary = name == config.dotfiles.profile;
          address = cfg.email;
          realName = user.name;
          # TODO add aliases, username, and password config to people
          # NOTE inherit (cfg) aliases userName passwordCommand;
          aliases = [];
          userName = "";
          passwordCommand = "";
          mbsync = {
            enable = true;
            create = "both";
            expunge = "both";
            remove = "both";
          };
          mu.enable = true;
          imap.host = "127.0.0.1";
          imap.port = 1143;
        });
        programs.mbsync.enable = true;
        programs.mu.enable = true;
        dotfiles.programs.emacs.orgFiles = [./email.org];
      }
      (mkIf stdenv.isLinux {
        services.mbsync.enable = true;
        services.mbsync.postExec = "${getExe mu} index";
      })
      (mkIf stdenv.isDarwin {
        launchd.agents = {
          hydroxide.enable = true;
          hydroxide.config = {
            RunAtLoad = true;
            KeepAlive.Crashed = true;
            Program = getExe hydroxide;
            ProgramArguments = ["imap"];
          };
          mbsync.enable = true;
          mbsync.config = {
            StartInterval = 900;
            Program = getExe isync;
            ProgramArguments = ["--all" "--verbose"];
          };
          mu-index.enable = true;
          mu-index.config = {
            StartInterval = 900;
            Program = getExe mu;
            ProgramArguments = ["index"];
          };
        };
      })
    ]);
  };
}
