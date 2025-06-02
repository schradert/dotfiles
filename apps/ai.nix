{
  dotfiles.home-manager = {
    config,
    lib,
    pkgs,
    ...
  }: {
    config = lib.mkIf config.dotfiles.profiles.workstation.enable {
      programs.gtt = {
        # TODO how can I set values in gtt.yaml automatically when it has state (like which language...)?
        enable = true;
        servers.api_key = {
          # TODO add api key secrets
          chatgpt.file = "/path/to/chatgpt-api-key.txt";
          deepl.file = "/path/to/deepl-api-key.txt";
          deeplx.file = "/path/to/deeplx-api-key.txt";
          libre.file = "/path/to/libre-api-key.txt";
        };
        # TODO host deeplx and libre!
        servers.host = {
          deeplx = "deeplx.hostname";
          libre = "libre.hostname";
        };
        keymap.exit = "C-q";
        keymap.clear = "C-c";
        # TODO how can I get the colors to come from autogeneration?
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
      home.packages = with pkgs; [
        openapi-tui
        nur.repos.dustinblackman.oatmeal
        tenere
      ];
    };
  };
}
