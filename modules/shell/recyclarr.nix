{
  canivete.deploy.nixos.modules.recyclarr = {
    config,
    lib,
    pkgs,
    ...
  }:
    with lib; let
      cfg = config.services.recyclarr;
      format = pkgs.formats.yaml {};
      configFile = format.generate "recyclarr.recyclarr.yml" cfg.config;
      settingsFile = format.generate "recyclarr.settings.yml" cfg.settings;
    in {
      options = with types; {
        services.recyclarr = {
          enable = mkEnableOption "Recyclarr";
          package = mkPackageOption pkgs "recyclarr" {};
          user = mkOption {
            type = str;
            description = "User account under which Recyclarr runs";
            default = "recyclarr";
          };
          group = mkOption {
            type = str;
            description = "Group under which Recyclarr runs";
            default = "recyclarr";
          };
          dataDir = mkOption {
            type = str;
            default = "/var/lib/recyclarr";
            description = "Root location for all files";
          };
          config = mkOption {
            type = nullOr format.type;
            description = "Contents of recyclarr.yml configuration file";
          };
          settings = mkOption {
            type = nullOr format.type;
            description = "Contents of settings.yml configuration file";
          };
        };
      };
      config = mkIf cfg.enable {
        environment.etc = mkMerge [
          (mkIf (cfg.config != null) {"recyclarr/recyclarr.yml".source = configFile;})
          (mkIf (cfg.settings != null) {"recyclarr/settings.yml".source = settingsFile;})
        ];
        systemd.tmpfiles.rules = ["d '${cfg.dataDir}/cache' 0700 '${cfg.user}' '${cfg.group}' - -"];
        systemd.services.recyclarr = {
          description = "Recyclarr";
          after = ["network.target"];
          wantedBy = ["multi-user.target"];
          preStart = ''
            ln -fs /etc/recyclarr/recyclarr.yml ${cfg.dataDir}/recyclarr.yml
            ln -fs /etc/recyclarr/settings.yml ${cfg.dataDir}/settings.yml
          '';
          serviceConfig = {
            User = cfg.user;
            Group = cfg.group;
            Restart = "on-failure";
            ExecStart = "${getExe cfg.package} sync --app-data ${cfg.dataDir}";
          };
        };
        users.groups = mkIf (cfg.group == "recyclarr") {recyclarr.gid = config.ids.gids.recyclarr;};
        users.users = mkIf (cfg.user == "recyclarr") {
          recyclarr = {
            uid = config.ids.uids.recyclarr;
            inherit (cfg) group;
            home = cfg.dataDir;
            createHome = true;
          };
        };
      };
    };
}
