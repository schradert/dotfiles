{
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
    home.modules.podman = {pkgs, ...}: {
      home.file.".local/bin/docker".source = "${pkgs.podman}/bin/podman";
      home.packages = with pkgs; [podman podman-compose podman-tui];
    };
    darwin.homeModules.podman = {
      config,
      lib,
      ...
    }: {
      home.activation.podmanMacInstallation = lib.hm.dag.entryAfter ["writeBoundary"] ''
        rootSock=/var/run/docker.sock
        dockerSockDir="${config.home.homeDirectory}/.docker/run"
        podmanSockDir="${config.home.sessionVariables.XDG_RUNTIME_DIR}/podman"
        mkdir -p "$dockerSockDir" "$podmanSockDir"
        ln -sf $rootSock "$dockerSockDir/docker.sock"
        ln -sf $rootSock "$podmanSockDir/podman.sock"
      '';
    };
    nixos.modules.podman.virtualisation.podman = {
      enable = true;
      dockerSocket.enable = true;
      defaultNetwork.settings.dns_enable = true;
    };
  };
}
