{
  # TODO use fish/carapace/zoxide/multiple completion
  # TODO https://github.com/nushell/nu_scripts
  # TODO https://github.com/nushell/awesome-nu
  # TODO https://nixos.wiki/wiki/Nushell
  # TODO https://github.com/nushell/nushell/discussions/12997
  # TODO all the nushell plugins
  # NOTE https://www.nushell.sh/cookbook/external_completers.html#fish-completer
  canivete.deploy.system.homeModules.nushell = {
    config,
    lib,
    ...
  }: let
    inherit (config.xdg) cacheHome;
    inherit (lib) flip mapAttrs mkIf mkOption types;
  in {
    options.dotfiles.programs.nushell.integrations = mkOption {
      type = with types; attrsOf str;
      default = {};
      description = "Command to generate nushell integration for each package name";
    };
    config = mkIf config.programs.nushell.enable {
      dotfiles.programs.emacs.orgFiles = [./nushell.org];
      programs.nushell = flip mapAttrs config.dotfiles.programs.nushell.integrations (name: cmd: {
        # Nushell prohibits conditionally sourcing/setting files/variables
        extraEnv = ''
          let cache = "${cacheHome}/${name}"
          if not ($cache | path exists) {
            mkdir $cache
          }
          ${cmd} | save --force ${cacheHome}/${name}/init.nu
        '';
        extraConfig = "source ${cacheHome}/${name}/init.nu";
      });
    };
  };
}
