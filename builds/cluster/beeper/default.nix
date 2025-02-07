{
  canivete.deploy.system.modules.chat = {lib, ...}: {
    options.dotfiles.profiles.chat.enable = lib.mkEnableOption "chat applications";
  };
}
