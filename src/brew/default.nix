{
  flake.homeModules.brew = {
    lib,
    pkgs,
    ...
  }: let
    brew = "/opt/homebrew/bin/brew";
  in
    lib.mkIf pkgs.stdenv.isDarwin {
      home.file.".config/brew/Brewfile".source = ./Brewfile;
      home.activation.homebrewSelfInstallation = lib.hm.dag.entryAfter ["linkGeneration"] ''
        if [ ! -x "${brew}" ] &>/dev/null; then
          $DRY_RUN_CMD ${pkgs.bash}/bin/bash \
            -c "$(${pkgs.curl}/bin/curl \
                --fail --silent --show-error --location \
                https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
      '';
      home.activation.homebrewPkgsInstallation = lib.hm.dag.entryAfter ["homebrewSelfInstallation"] ''
        export HOMEBREW_BUNDLE_NO_LOCKFILE_WRITE_WARNING=1
        $DRY_RUN_CMD "${brew}" bundle check --file ${./Brewfile} \
            || "${brew}" bundle install --file ${./Brewfile} --cleanup
        # $DRY_RUN_CMD zsh -c "'${brew}' install emacs-plus@29 --with-native-comp --with-modern-doom3-icon --with-xwidgets --with-poll --with-imagemagick --with-dbus"
      '';
    };
}
