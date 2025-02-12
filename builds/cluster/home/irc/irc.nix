{lib, ...}: {
  # NOTE CHANNELS
  # TODO https://github.com/ergochat/ergo
  # TODO https://codeberg.org/emersion/soju
  # TODO https://github.com/progval/Limnoria
  # TODO https://github.com/oddluck/limnoria-plugins
  # TODO https://github.com/Libera-Chat/ozone
  # TODO https://codeberg.org/emersion/gamja
  # TODO https://sr.ht/~delthas/senpai/
  # TODO https://www.mirc.com/ vs irssi vs weechat
  # #invidious:libera.chat
  # #django:libera.chat
  # #spritely:libera.chat
  # #indieweb:libera.chat
  # #protondb:libera.chat
  # #octoprint:libera.chat
  options.dotfiles.irc.channels = lib.mkOption {
    type = with lib.types; listOf str;
    default = [];
  };
  config.canivete.deploy.system.homeModules.irc.dotfiles.programs.emacs.orgFiles = [./irc.org];
}
