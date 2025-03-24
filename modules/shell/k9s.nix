{
  # TODO add HolmesGPT plugin https://github.com/derailed/k9s/blob/master/plugins/ai-incident-investigaton.yaml
  # TODO build https://github.com/hcavarsan/kftray
  # TODO https://github.com/derailed/k9s/blob/master/plugins/carvel.yaml
  canivete.deploy.system.homeModules.k9s = {
    config,
    lib,
    pkgs,
    ...
  }: {
    config = lib.mkIf (config.dotfiles.workstation.enable || config.canivete.kubernetes.enable) {
      dotfiles.programs.emacs.orgFiles = [./kubernetes.org];
      home.packages = with pkgs; [kubectl kubernetes-helm kubetui kdash ktop];
      programs.k9s.enable = true;
      # Reference "https://github.com/derailed/k9s/blob/master/skins/dracula.yaml"
      programs.k9s.skins.skin.k9s = let
        fgColor = "#f8f8f2";
        bgColor = "#282a36";
        selection = "#44475a";
        comment = "#6272a4";
        cyan = "#8be9fd";
        green = "#50fa7b";
        orange = "#ffb86c";
        purple = "#bd93f9";
        pink = "#ff79c6";
        red = "#ff5555";
        yellow = "#f1fa8c";
      in {
        body.fgColor = fgColor;
        body.bgColor = bgColor;
        body.logoColor = purple;
        dialog = {
          inherit fgColor bgColor;
          buttonFgColor = fgColor;
          buttonBgColor = purple;
          buttonFocusFgColor = yellow;
          buttonFocusBgColor = pink;
          labelFgColor = orange;
          fieldFgColor = fgColor;
        };
        frame = {
          border.fgColor = selection;
          border.focusColor = selection;
          menu.fgColor = fgColor;
          menu.keyColor = pink;
          menu.numKeyColor = pink;
          crumbs.fgColor = fgColor;
          crumbs.bgColor = selection;
          crumbs.activeColor = selection;
          status = {
            newColor = cyan;
            modifyColor = purple;
            addColor = green;
            errorColor = red;
            highlightColor = orange;
            killColor = comment;
            completedColor = comment;
          };
          title = {
            inherit fgColor;
            bgColor = selection;
            highlightColor = orange;
            counterColor = purple;
            filterColor = pink;
          };
        };
        info.fgColor = pink;
        info.sectionColor = fgColor;
        prompt.fgColor = fgColor;
        prompt.bgColor = bgColor;
        prompt.suggestColor = purple;
        views = {
          charts.bgColor = "default";
          charts.defaultDialColors = [purple red];
          charts.defaultChartColors = [purple red];
          logs = {
            inherit fgColor bgColor;
            indicator = {
              inherit fgColor;
              bgColor = purple;
              toggleOnColor = green;
              toggleOffColor = cyan;
            };
          };
          table = {
            inherit fgColor bgColor;
            header = {
              inherit fgColor bgColor;
              sorterColor = cyan;
            };
          };
          xray = {
            inherit fgColor bgColor;
            cursorColor = selection;
            graphicColor = purple;
            showIcons = false;
          };
          yaml.keyColor = pink;
          yaml.colonColor = purple;
          yaml.valueColor = fgColor;
        };
      };
    };
  };
}
