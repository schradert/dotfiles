{lib, ...}: let
  inherit (lib) getExe mkEnableOption mkIf mkMerge;
in {
  flake.overlays.podman = _: prev:
    with prev; {
      # TODO Build vfkit into podman on Darwin (undeclared identifiers?)
      # NOTE: https://github.com/NixOS/nixpkgs/issues/305868
      # vfkit = buildGoModule rec {
      #   pname = "vfkit";
      #   version = "0.5.1";
      #   src = fetchFromGitHub {
      #     owner = "crc-org";
      #     repo = pname;
      #     rev = "v${version}";
      #     hash = "sha256-9iPr9VhN60B6kBikdEIFAs5mMH+VcmnjGhLuIa3A2JU=";
      #   };
      #   vendorHash = "sha256-6O1T9aOCymYXGAIR/DQBWfjc2sCyU/nZu9b1bIuXEps=";
      #   buildInputs = lib.optionals stdenv.isDarwin (with darwin.apple_sdk.frameworks; [Virtualization Cocoa]);
      #   meta.mainProgram = pname;
      # };
    };
  canivete.deploy = {
    system.modules.containers.options.dotfiles.containers = mkEnableOption "containerization tooling";
    system.homeModules.containers = {
      config,
      lib,
      pkgs,
      ...
    }: {
      config = mkIf config.dotfiles.containers (mkMerge [
        {
          dotfiles.programs.emacs = {
            dependencies = [pkgs.dockerfile-language-server-nodejs];
            orgFiles = [./podman.org];
          };
          home.sessionVariables.DOCKER_CONFIG = "${config.xdg.configHome}/docker";
          home.sessionVariables.DOCKER_HOST = "unix:///${config.home.sessionVariables.XDG_RUNTIME_DIR}/podman/podman.sock";
          home.shellAliases.docker = getExe pkgs.podman;
          home.packages = with pkgs; [k3d podman podman-compose podman-tui lazydocker oxker dive];
          # TODO build https://github.com/robertpsoane/ducker
        }
        (mkIf pkgs.stdenv.isDarwin {
          # TODO make sure that the podman socket is found
          home.activation.podmanMacInstallation = lib.hm.dag.entryAfter ["writeBoundary"] ''
            rootSock=/var/run/docker.sock
            dockerSockDir="${config.home.homeDirectory}/.docker/run"
            podmanSockDir="${config.home.homeDirectory}/.run/podman"
            mkdir -p "$dockerSockDir" "$podmanSockDir"
            ln -sf $rootSock "$dockerSockDir/docker.sock"
            ln -sf $rootSock "$podmanSockDir/podman.sock"
          '';
        })
      ]);
    };
    nixos.modules.containers = {config, ...}: {
      config = mkIf config.dotfiles.containers {
        virtualisation.podman = {
          enable = true;
          dockerSocket.enable = true;
          defaultNetwork.settings.dns_enable = true;
        };
      };
    };
    nixos.homeModules.containers = {
      config,
      pkgs,
      ...
    }: {
      config = mkIf config.dotfiles.containers {
        home.packages = with pkgs; [boxbuddy distrobox distrobox-tui host-spawn];
      };
    };
  };
}
