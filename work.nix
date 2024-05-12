{
  config,
  inputs,
  nix,
  withSystem,
  ...
}:
with nix; {
  people.users.tristan.profiles.work.email = "tristan@climaxfoods.com";
  flake.darwinConfigurations.morgenmuffel = withSystem "aarch64-darwin" ({
    pkgs,
    system,
    ...
  }:
    inputs.nix-darwin.lib.darwinSystem {
      inherit pkgs system;
      specialArgs = inputs.self.nixos-flake.lib.specialArgsFor.darwin;
      modules =
        attrValues inputs.self.systemModules
        ++ toList {
          networking.hostName = "morgenmuffel";
          homebrew.enable = true;
          homebrew.brews = ["libtool" "vfkit"];
          homebrew.casks = [
            "android-studio"
            "anki"
            "beeper"
            "bitwarden"
            "brave-browser"
            "clickup"
            # "dracula-wallpaper"
            "element"
            "godot"
            "google-drive"
            "lulu"
            "protonvpn"
            "session"
            "signal"
            "teamviewer"
            "zotero"
          ];
          homebrew.taps = [
            "cfergeau/crc"
            # "dracula/install"
          ];
          nix.settings.trusted-users = [config.people.me];
          nix.useDaemon = true;
          services.karabiner-elements.enable = true;
          system.defaults.dock = {
            autohide = true;
            orientation = "left";
            static-only = true;
          };
          system.stateVersion = 4;
        };
    });
  flake.overlays.gke-gcloud-auth-plugin = inputs.gke-gcloud-auth-plugin-flake.overlays.default;
  perSystem = {
    pkgs,
    system,
    ...
  }: {
    canivete.opentofu.workspaces.work = {
      plugins = ["opentofu/null" "opentofu/external"];
      modules.default = {pkgs, ...}: let
        nixFlags = "--extra-experimental-features \"nix-command flakes\"";
      in {
        data.external.darwin_eval.program = pkgs.execBash ''
          nix ${nixFlags} path-info --derivation ${inputs.self}#darwinConfigurations.morgenmuffel.config.system.build.toplevel | \
              ${pkgs.jq}/bin/jq --raw-input '{"drv":.}'
        '';
        resource.null_resource.darwin_switch = {
          triggers.drv = "\${ data.external.darwin_eval.result.drv }";
          provisioner.local-exec.command = "nix ${nixFlags} run ${inputs.nix-darwin}# -- switch --flake ${inputs.self}#morgenmuffel";
        };
        data.external.home_eval.program = pkgs.execBash ''
          nix ${nixFlags} path-info --derivation ${inputs.self}#legacyPackages.${system}.homeConfigurations.tristan.config.home.activationPackage | \
              ${pkgs.jq}/bin/jq --raw-input '{"drv":.}'
        '';
        resource.null_resource.home_switch = {
          depends_on = ["null_resource.darwin_switch"];
          triggers.drv = "\${ data.external.home_eval.result.drv }";
          provisioner.local-exec.command = "nix ${nixFlags} run ${inputs.self}#homeConfigurations.tristan.activationPackage";
        };
      };
    };
    legacyPackages.homeConfigurations.tristan = inputs.self.nixos-flake.lib.mkHomeConfiguration pkgs (home: {
      imports = attrValues inputs.self.homeModules;
      options.dotfiles.graphical.enable = mkEnableOption "graphical tools (i.e. not headless)";
      config = {
        _module.args.nix = nix;
        dotfiles.graphical.enable = true;
        dotfiles.hostname = "morgenmuffel";
        dotfiles.profile = "work";
        programs.ssh.matchBlocks = mapAttrs (_:
          mergeAttrs {
            identityFile = "${home.config.home.homeDirectory}/.ssh/work";
            user = "terraform";
          }) {};
        programs.zsh.oh-my-zsh.plugins = ["brew" "gcloud"];
        # TODO remove all of the extra logging (why isn't /dev/null working on relevant commands?)
        home.activation.prepareFutoffo = let
          gcloud = getExe pkgs.google-cloud-sdk;
        in
          home.lib.hm.dag.entryAfter ["linkGeneration"] ''
            chmod +x ${home.config.home.shellAliases.futoffo}
            if [[ -z $(${gcloud} auth list --filter active | grep '@climaxfoods.com' | ${pkgs.gawk}/bin/awk '{print $NF}' 2> /dev/null) ]]; then
               ${gcloud} auth login
            fi
            if [[ ! $(grep -q gcloud "$HOME/.docker/config.json" &> /dev/null) ]]; then
               ${gcloud} auth configure-docker
            fi
          '';
        home.sessionVariables.XDG_RUNTIME_DIR = "${home.config.home.homeDirectory}/.run";
        home.activation.podmanMacInstallation = home.lib.hm.dag.entryAfter ["writeBoundary"] ''
          rootSock=/var/run/docker.sock
          dockerSockDir="${home.config.home.homeDirectory}/.docker/run"
          podmanSockDir="${home.config.home.sessionVariables.XDG_RUNTIME_DIR}/podman"
          mkdir -p "$dockerSockDir" "$podmanSockDir"
          ln -sf $rootSock "$dockerSockDir/docker.sock"
          ln -sf $rootSock "$podmanSockDir/podman.sock"
        '';
        home.packages = with pkgs; [google-cloud-sdk gke-gcloud-auth-plugin pngpaste python312 raycast spotify];
        home.shellAliases.futoffo = "\"${home.config.home.homeDirectory}/Google Drive/Shared drives/software/futoffo/start_docker.command\"";
        launchd.agents = let
          config.RunAtLoad = true;
          config.KeepAlive.Crashed = true;
        in {
          bitwarden.enable = true;
          bitwarden.config = config // {Program = "/Applications/Bitwarden.app/Contents/MacOS/Bitwarden";};
          brave.enable = true;
          brave.config = config // {Program = "/Applications/Brave Browser.app/Contents/MacOS/Brave Browser";};
          clickup.enable = true;
          clickup.config = config // {Program = "/Applications/ClickUp.app/Contents/MacOS/ClickUp";};
          gdrive.enable = true;
          gdrive.config = config // {Program = "/Applications/Google Drive.app/Contents/MacOS/Google Drive";};
          lulu.enable = true;
          lulu.config = config // {Program = "/Applications/LuLu.app/Contents/MacOS/LuLu";};
          protonvpn.enable = true;
          protonvpn.config = config // {Program = "/Applications/ProtonVPN.app/Contents/MacOS/ProtonVPN";};
          raycast.enable = true;
          raycast.config = config // {Program = "${pkgs.raycast}/Applications/Raycast.app/Contents/MacOS/Raycast";};
          wezterm.enable = true;
          wezterm.config = config // {Program = "${pkgs.wezterm}/Applications/WezTerm.app/Contents/MacOS/WezTerm";};
        };
      };
    });
  };
}
