{
  # TODO is it possible to add navi as a zellij widget like you can for tmux?
  # TODO add theming!
  canivete.deploy = {
    system.homeModules.navi = {
      canivete,
      config,
      lib,
      pkgs,
      ...
    }: let
      inherit (config.dotfiles.programs) navi;
      inherit (lib) concatStringsSep forEach getAttr getExe hm mkEnableOption mkIf mkMerge mkOption types;
      inherit (types) coercedTo listOf package str submodule;
      navi' = getExe config.programs.navi.package;
    in {
      options.dotfiles.programs.navi = {
        enable = mkEnableOption "navi";
        autoupdate.enable = mkEnableOption "navi repository autoupdater" // {default = navi.autoupdate.repositories != [];};
        autoupdate.repositories = mkOption {
          type = listOf (coercedTo str (url: let
              matches = builtins.match ".+/(.+)/(.+)$" url;
            in {
              inherit url;
              owner = builtins.elemAt matches 0;
              repo = builtins.elemAt matches 1;
            }) (let
              strOption = mkOption {type = str;};
            in
              submodule {
                options.owner = strOption;
                options.repo = strOption;
                options.url = strOption;
              }));
          default = [];
          description = "Git repositories to clone regularly for updated cheatsheets";
        };
        autoupdate.script = mkOption {
          type = package;
          readOnly = true;
        };
      };
      config = mkMerge [
        {
          dotfiles.programs.navi.autoupdate = {
            # TODO how can I determine what these are at eval time? build denisidoro/cheats?
            repositories = map (canivete.prefix "https://github.com") [
              "denisidoro/cheats"
              "denisidoro/navi-tldr-pages"
              "denisidoro/dotfiles"
              "mrVanDalo/navi-cheats"
              "chazeon/my-navi-cheats"
              "caojianhua/MyCheat"
              "Kidman1670/cheats"
              "isene/cheats"
              "m42martin/navi-cheats"
              "infosecstreams/cheat.sheets"
              "prx2090/cheatsheets-for-navi"
              "papanito/cheats"
            ];
            script = let
              git' = getExe config.programs.git.package;
              toRepoBashArray = attr: "${attr}s=(${concatStringsSep " " (forEach navi.autoupdate.repositories (getAttr attr))})";
            in
              pkgs.writeShellScript "navi-autoupdate.sh" ''
                MAX_CONCURRENT_PROCESSES=8
                ${toRepoBashArray "owner"}
                ${toRepoBashArray "repo"}
                ${toRepoBashArray "url"}
                for i in "''${!urls[@]}"; do
                  location="$(${navi'} info cheats-path)/''${owners[i]}__''${repos[i]}"
                  if [[ $1 == clone ]]; then
                    ${git'} clone "''${urls[i]}" "$location" &
                  elif [[ $1 == pull ]]; then
                    ${git'} -C "$location" pull --quiet origin &
                  fi
                  if [[ $(jobs -r -p | wc -l) -ge $MAX_CONCURRENT_PROCESSES ]]; then wait -n; fi
                done
                wait
              '';
          };
        }
        (mkIf navi.enable (mkMerge [
          {
            dotfiles.programs = {
              elvish.integrations = ["${navi'} widget elvish | slurp"];
              nushell.integrations.navi = "${navi'} widget nushell";
              xonsh.packages = ps: [ps.xontrib-navi];
              xonsh.xontribs = ["navi"];
            };
            programs.navi.enable = true;
            programs.navi.settings = {};
          }
          (mkIf navi.autoupdate.enable {
            home.activation.navi = hm.dag.entryAfter ["writeBoundary"] "${navi.autoupdate.script} clone";
          })
        ]))
      ];
    };
    darwin.homeModules.navi = {
      config,
      lib,
      options,
      ...
    }: let
      inherit (config.dotfiles.programs.navi) enable autoupdate;
    in {
      # TODO why doesn't this work?
      # options.dotfiles.programs.navi.autoupdate.timer = options.launchd.agents.options.config.StartCalendarInterval;
      options.dotfiles.programs.navi.autoupdate.timer = lib.mkOption {type = with lib.types; listOf (attrsOf int);};
      config = lib.mkMerge [
        {
          dotfiles.programs.navi.autoupdate.timer = lib.mkDefault builtins.genList (i: {Hour = i * 2;}) (24 / 2);
        }
        (lib.mkIf (enable && autoupdate.enable) {
          launchd.agents.navi = {
            enable = true;
            config = {
              KeepAlive.Crashed = true;
              ProgramArguments = [autoupdate.script "pull"];
              RunAtLoad = true;
              StartCalendarInterval = autoupdate.timer;
            };
          };
        })
      ];
    };
    nixos.homeModules.navi = {
      config,
      lib,
      utils,
      ...
    }: let
      inherit (config.dotfiles.programs.navi) enable autoupdate;
      inherit (lib) mkDefault mkIf mkMerge;
    in {
      options.dotfiles.programs.navi.autoupdate.timer = utils.systemdUtils.unitOptions.timerOptions.options.timerConfig;
      config = mkMerge [
        {
          dotfiles.programs.navi.autoupdate.timer = {
            Persistent = mkDefault true;
            OnCalendar = mkDefault "*-*-* *:00/2:00";
          };
        }
        (mkIf (enable && autoupdate.enable) {
          systemd.user.services.navi.Service = {
            Type = "oneshot";
            ExecStart = "${autoupdate.script} pull";
          };
          systemd.user.timers.navi = {
            Install.WantedBy = ["timers.target"];
            Timer = autoupdate.timer;
          };
        })
      ];
    };
  };
}
