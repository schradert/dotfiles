{
  perSystem = {pkgs, ...}: {
    # TODO allow overriding inputs
    packages.rfv = pkgs.writeShellApplication {
      name = "rfv";
      runtimeInputs = with pkgs; [ripgrep fzf vim bat];
      runtimeEnv.RELOAD = "reload:rg --column --color=always --smart-case {q} || :";
      runtimeEnv.OPENER = "if [[ $FZF_SELECT_COUNT -eq 0 ]]; then vim {1} +{2}; else vim +cw -q {+f}; fi";
      excludeShellChecks = ["SC2016"];
      text = ''
        fzf --disabled --ansi --multi \
            --bind "start:$RELOAD" \
            --bind "change:$RELOAD" \
            --bind "enter:become:$OPENER" \
            --bind "ctrl-o:execute:$OPENER" \
            --bind "alt-a:select-all,alt-d:deselect-all,ctrl-/:toggle-preview" \
            --delimiter : \
            --preview "bat --style=full --color=always --highlight-line {2} {1}" \
            --preview-window "~4,+{2}+4/3,<60(up)" \
            --query "$*"
      '';
    };
  };
  canivete.deploy.system.homeModules.rfv = {perSystem, ...}: {home.packages = [perSystem.self'.packages.rfv];};
}
