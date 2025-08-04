{
  dotfiles.home-manager = {
    config,
    flake,
    lib,
    nixosConfig,
    pkgs,
    ...
  }: {
    imports = [flake.inputs.mynur.homeManagerModules.gtt];
    config = lib.mkIf config.dotfiles.profiles.client.workstation.enable {
      # sops.secrets."ai/open-webui" = {};
      programs.doom-emacs.tangle = {
        init.tools.llm = true;
        # TODO do I need to specify models here? what about "everything"
        # TODO add open-webui key
        # TODO point to cluster
        # :key (f-read "${config.sops.secrets."ai/open-webui".path}")
        config = ''
          (after! gptel
            (setq! gptel-backend
                   (gptel-make-openai "OpenWebUI"
                     :host "localhost:${builtins.toString nixosConfig.services.open-webui.port}"
                     :protocol "http"
                     :endpoint "/api/chat/completions"
                     :stream t
                     :models '())))
        '';
      };
      programs.gtt = {
        # TODO how can I set values in gtt.yaml automatically when it has state (like which language...)?
        enable = false;
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
