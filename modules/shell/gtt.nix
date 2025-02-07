{
  # TODO how can I get the colors to come from autogeneration?
  # TODO how can I set values in gtt.yaml automatically when it has state (like which language...)?
  # TODO add api key secrets
  # TODO host deeplx and libre!
  canivete.deploy.system.homeModules.gtt = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (config.dotfiles.programs) gtt;
    inherit (lib) mkEnableOption mkPackageOption mkIf mkOption mkMerge;
    yaml = pkgs.formats.yaml {};
  in {
    options.dotfiles.programs.gtt = {
      enable = mkEnableOption "gtt translation TUI";
      package = mkPackageOption pkgs "gtt" {};
      servers = mkOption {
        inherit (yaml) type;
        default = {};
      };
      keymap = mkOption {
        inherit (yaml) type;
        default = {};
      };
      theme = mkOption {
        inherit (yaml) type;
        default = {};
      };
    };
    config = mkIf gtt.enable {
      dotfiles.programs.gtt = {
        servers.api_key = {
          chatgpt.file = "/path/to/chatgpt-api-key.txt";
          deepl.file = "/path/to/deepl-api-key.txt";
          deeplx.file = "/path/to/deeplx-api-key.txt";
          libre.file = "/path/to/libre-api-key.txt";
        };
        servers.host = {
          deeplx = "deeplx.hostname";
          libre = "libre.hostname";
        };
        keymap.exit = "C-q";
        keymap.clear = "C-c";
        theme.dracula = {
          bg = "0x282a36";
          fg = "0xf8f8f2";
          gray = "0x44475a";
          red = "0xff5555";
          green = "0x50fa7b";
          yellow = "0xf1fa8c";
          # This is actually pink...
          blue = "0xff79c6";
          purple = "0xbd93f9";
          cyan = "0x8be9fd";
          orange = "0xffb86c";
        };
      };
      home.packages = [gtt.package];
      xdg.configFile = mkMerge [
        (mkIf (gtt.servers != {}) {"gtt/server.yaml".source = yaml.generate "gtt.server.yaml" gtt.servers;})
        (mkIf (gtt.keymap != {}) {"gtt/keymap.yaml".source = yaml.generate "gtt.keymap.yaml" gtt.keymap;})
        (mkIf (gtt.theme != {}) {"gtt/theme.yaml".source = yaml.generate "gtt.theme.yaml" gtt.theme;})
      ];
    };
  };
}
