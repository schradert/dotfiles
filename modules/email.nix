{nix, ...}: {
  canivete.deploy = {
    system.homeModules.email = {pkgs, ...}: {
      home.packages = with pkgs; [mu mu.mu4e isync hydroxide];
      accounts.email.accounts.Proton = {
        # TODO alot contact completion
        # TODO connect this to people
        # TODO add more accounts
        # TODO can I use a shared mbsync config?
        # TODO activate msmtp and SMTP hydroxide server
        primary = true;
        address = "tristanschrader@proton.me";
        aliases = ["t0rdos@pm.me"];
        realName = "Tristan Schrader";
        userName = "tristanschrader";
        passwordCommand = "${pkgs.bitwarden-cli}/bin/bw get password \"proton (main)\"";
        # msmtp.enable = true;
        mbsync = {
          enable = true;
          create = "both";
          expunge = "both";
          remove = "both";
        };
        mu.enable = true;
        imap = {
          host = "127.0.0.1";
          port = 1143;
        };
      };
      # programs.msmtp.enable = true;
      programs.mbsync.enable = true;
      programs.mu.enable = true;
    };
    nixos.homeModules.email = {pkgs, ...}: {
      # TODO what else to configure
      services.mbsync = {
        enable = true;
        postExec = "${pkgs.mu}/bin/mu index";
      };
    };
    darwin.homeModules.email = {pkgs, ...}: {
      launchd.agents.hydroxide = {
        enable = true;
        config.RunAtLoad = true;
        config.KeepAlive.Crashed = true;
        config.Program = nix.getExe pkgs.hydroxide;
        config.ProgramArguments = ["imap"];
      };
      launchd.agents.mbsync = {
        enable = true;
        config.StartInterval = 900;
        config.Program = "${pkgs.isync}/bin/mysnc";
        config.ProgramArguments = ["--all" "--verbose"];
      };
      launchd.agents.mu-index = {
        enable = true;
        config.StartInterval = 900;
        config.Program = "${pkgs.mu}/bin/mu";
        config.ProgramArguments = ["index"];
      };
    };
  };
}
