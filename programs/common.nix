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
  flake.homeModules.default = {pkgs, ...}: {
    home.packages = with pkgs; [
      aria2
      cheat
      cmake
      dig
      fd
      file
      glab
      iftop
      inxi
      k3d
      lazydocker
      libtool
      lsof
      nmap
      nodejs
      openssl
      podman
      podman-compose
      podman-tui
      procps
      ranger
      rclone
      ripgrep
      speedtest-cli
      sqlite
      thefuck
      tig
      tldr
      tree
      unzip
      xplr
    ];
    home.file.".local/bin/docker".source = "${pkgs.podman}/bin/podman";
    programs = {
      bash.enable = true;
      bat.enable = true;
      btop.enable = true;
      dircolors.enable = true;
      direnv.enable = true;
      direnv.nix-direnv.enable = true;
      eza.enable = true;
      fzf.enable = true;
      gpg.enable = true;
      home-manager.enable = true;
      htop.enable = true;
      jq.enable = true;
      navi.enable = true;
      wezterm.enable = true;
      zoxide.enable = true;
    };
  };
}
