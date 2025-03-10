{
  perSystem.canivete.pre-commit.settings.hooks.typos.settings.ignored-words = ["regist"];
  canivete.deploy.nixos.homeModules.chiaki = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (config.dotfiles.programs.steam.external.chiaki) enable package;
    inherit (lib) mkEnableOption mkIf mkPackageOption getExe;
    images = pkgs.stdenv.mkDerivation {
      name = "chiaki-ng-images";
      inherit (package) version;
      src = package.src + "/assets/chiaki-ngImages.tar.xz";
      unpackPhase = "tar -xvf $src";
      installPhase = "install --mode 755 -D --target-directory $out chiaki-ng-images/steam_*.png";
    };
    launcher = pkgs.writeShellApplication {
      name = "chiaki-launcher";
      runtimeInputs = [package];
      text = ''
        usage() {
            echo "Usage: $0 --conf <chiaki_config_file> [--timeout <timeout>]"
        }

        # Parse arguments
        while [[ $# -gt 0 ]]; do
            case "$1" in
                --conf) conf="$2"; shift 2;;
                --timeout) timeout="$2"; shift 2;;
                -h|--help) usage; exit 0;;
                *) echo "Error: unknown option: $1"; usage; exit 1;;
            esac
        done

        # Argument validation
        [[ -z $conf ]] && { echo "Error: --conf must be specified with Chiaki config location"; usage; exit 1; }
        timeout="''${timeout:-35}"

        # Attribute parsing
        console="$(grep server_nickname "$conf" | cut -d= -f2)"
        host="$(grep host= "$conf" | cut -d= -f2)"
        key="$(grep regist_key "$conf" | cut -d\( -f2 | cut -d\\ -f1)"

        # Await ready status by attempting wakeup
        elapsed=0
        while ! chiaki discover --host "$host" | grep -q ready; do
            if [[ $elapsed -gt $timeout ]]; then
                echo "Error: console failed to wake up and reach ready status"
                exit 1
            fi
            chiaki wakeup --ps5 --host "$host" --registkey "$key"
            sleep 5
            elapsed=$((elapsed + 5))
        done

         # Profit
        chiaki stream "$console" "$host"
      '';
    };
    conf = "${config.home.homeDirectory}/.config/Chiaki/Chiaki.conf";
  in {
    options.dotfiles.programs.steam.external.chiaki = {
      enable = mkEnableOption "chiaki";
      package = mkPackageOption pkgs "chiaki-ng" {};
    };
    config = mkIf enable {
      home.packages = [package];
      # NOTE this only works for a single user with a single PS5 console
      # TODO extend this to allow multiple consoles and remote connection
      # TODO how to connect chiaki device declaratively?
      dotfiles.programs.steam.external.manual.chiaki-ng = {
        shortcut.exe = getExe (pkgs.wrapFlags launcher "--add-flags \"--conf ${conf}\"");
        assets = {
          icon = images + "/steam_icon.png";
          logo = images + "/steam_logo.png";
          hero = images + "/steam_hero.png";
          banner = images + "/steam_landscape.png";
          portrait = images + "/steam_portrait.png";
        };
      };
    };
  };
}
