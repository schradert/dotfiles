{
  dotfiles.darwin = {
    config,
    lib,
    ...
  }: {
    config = lib.mkIf config.dotfiles.profiles.workstation.enable {
      homebrew.brews = ["vfkit"];
    };
  };
  dotfiles.home-manager = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) getExe hm mkIf mkMerge;
    inherit (pkgs.stdenv.hostPlatform) isDarwin isLinux;
  in {
    config = mkIf config.dotfiles.workstation.enable (mkMerge [
      {
        programs.doom-emacs = {
          extraBinPackages = [pkgs.dockerfile-language-server-nodejs pkgs.dockfmt];
          tangle.init.tools.docker = ["+lsp"];
          tangle.config = "(after! docker (setq docker-image-run-arguments '(\"--interactive\" \"--tty\" \"--rm\")))";
        };
        home.sessionVariables.DOCKER_CONFIG = "${config.xdg.configHome}/docker";
        home.sessionVariables.DOCKER_HOST = "unix:///${config.home.sessionVariables.XDG_RUNTIME_DIR}/podman/podman.sock";
        home.shellAliases.docker = getExe pkgs.podman;
        home.packages = with pkgs; [k3d podman podman-compose podman-tui lazydocker oxker dive];
      }
      (mkIf isDarwin {
        # TODO make sure that the podman socket is found
        home.activation.podmanMacInstallation = hm.dag.entryAfter ["writeBoundary"] ''
          rootSock=/var/run/docker.sock
          dockerSockDir="${config.home.homeDirectory}/.docker/run"
          podmanSockDir="${config.home.homeDirectory}/.run/podman"
          mkdir -p "$dockerSockDir" "$podmanSockDir"
          ln -sf $rootSock "$dockerSockDir/docker.sock"
          ln -sf $rootSock "$podmanSockDir/podman.sock"
        '';
      })
      (mkIf isLinux {
        home.packages = with pkgs; [boxbuddy distrobox distrobox-tui host-spawn];
      })
    ]);
  };
  dotfiles.nixos = {
    config,
    lib,
    ...
  }: {
    config = lib.mkIf config.dotfiles.profiles.workstation.enable {
      virtualisation.podman = {
        enable = true;
        dockerSocket.enable = true;
        defaultNetwork.settings.dns_enable = true;
      };
    };
  };
}
