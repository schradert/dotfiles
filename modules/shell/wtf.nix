{nix, ...}:
with nix; {
  canivete.deploy.system.homeModules.wtf = {
    config,
    pkgs,
    ...
  }: let
    inherit (config.dotfiles.programs) wtf;
  in {
    options.dotfiles.programs.wtf = {
      enable = mkEnabledOption "wtfutil";
      config = mkOption {
        type = nullOr package;
        description = "Wtfutil config file";
        default = null;
      };
      basePackage = mkPackageOption pkgs "wtf" {};
      finalPackage = mkOption {
        type = package;
        description = "Final configured wtfutil executable";
        default =
          if wtf.config == null
          then wtf.basePackage
          else pkgs.wrapProgram wtf.basePackage "wtfutil" "wtfutil" "--add-flags \"--config=${wtf.config}\"" {};
      };
    };
    config = {
      home.packages = mkIf wtf.enable [wtf.finalPackage];
      dotfiles.programs.wtf.config = pkgs.writers.writeYAML "wtfutil.yaml" {
        wtf = {
          colors = {
            background = "black";
            border.focusable = "darkslateblue";
            border.focused = "orange";
            border.normal = "gray";
            checked = "yellow";
            highlight.fore = "black";
            highlight.back = "gray";
            rows.even = "yellow";
            rows.odd = "white";
          };
          grid.columns = [35 35 35 35];
          grid.rows = [10 10 10 10 4];
          mods = {
            europe_time = {
              enabled = true;
              title = "Europe";
              type = "clocks";
              colors.rows.even = "lightblue";
              colors.rows.odd = "white";
              refreshInterval = 15;
              position = {
                top = 0;
                left = 0;
                height = 1;
                width = 1;
              };

              locations.GMT = "Etc/GMT";
              locations.Berlin = "Europe/Berlin";
              locations.London = "Europe/London";
              sort = "alphabetical";
            };
            americas_time = {
              enabled = true;
              title = "Americas";
              type = "clocks";
              colors.rows.even = "lightblue";
              colors.rows.odd = "white";
              refreshInterval = 15;
              position = {
                top = 0;
                left = 1;
                height = 1;
                width = 1;
              };

              locations.UTC = "Etc/UTC";
              locations.Los_Angeles = "America/Los_Angeles";
              locations.New_York = "America/New_York";
              sort = "alphabetical";
            };
            battery = {
              enabled = true;
              title = "⚡️";
              type = "power";
              refreshInterval = 15;
              position = {
                top = 1;
                left = 3;
                height = 1;
                width = 1;
              };
            };
            todolist = {
              enabled = true;
              title = "Todos";
              type = "todo";
              colors.highlight.fore = "black";
              colors.highlight.back = "orange";
              refreshInterval = 3600;
              position = {
                top = 1;
                left = 0;
                height = 2;
                width = 1;
              };

              checkedIcon = "X";
              colors.checked = "gray";
              filename = pkgs.writeText "todo.yml" "";
            };
            ip = {
              enabled = true;
              title = "My IP";
              type = "ipinfo";
              colors.name = "lightblue";
              colors.value = "white";
              refreshInterval = 150;
              position = {
                top = 0;
                left = 2;
                height = 1;
                width = 2;
              };
            };
            security_info = {
              enabled = true;
              title = "Staying safe";
              type = "security";
              refreshInterval = 3600;
              position = {
                top = 1;
                left = 2;
                height = 1;
                width = 1;
              };
            };
            readme = {
              enabled = true;
              title = "Config";
              type = "textfile";
              refreshInterval = 3600;
              position = {
                top = 1;
                left = 1;
                height = 1;
                width = 1;
              };

              format = true;
              formatStyle = "monokai";
              # TODO reference the outPath of this configuration without infinite recursion
              # filePaths = [wtf.config.outPath];
            };
            news = {
              enabled = true;
              title = "Hacker News";
              type = "hackernews";
              refreshInterval = 900;
              position = {
                top = 2;
                left = 1;
                height = 1;
                width = 3;
              };

              storyType = "top";
              numberOfStories = 10;
            };
            resources = {
              enabled = true;
              title = "Resources";
              type = "resourceusage";
              refreshInterval = 1;
              position = {
                top = 3;
                left = 0;
                height = 2;
                width = 1;
              };
            };
            uptime = {
              enabled = true;
              title = "Uptime";
              type = "cmdrunner";
              refreshInterval = 30;
              position = {
                top = 4;
                left = 1;
                height = 1;
                width = 3;
              };

              cmd = "${pkgs.coreutils}/bin/uptime";
              args = [];
            };
            disks = {
              enabled = true;
              title = "Disks";
              type = "cmdrunner";
              refreshInterval = 3600;
              position = {
                top = 3;
                left = 1;
                height = 1;
                width = 3;
              };

              cmd = "${pkgs.coreutils}/bin/df";
              args = ["--human-readable"];
            };
          };
        };
      };
    };
  };
}
