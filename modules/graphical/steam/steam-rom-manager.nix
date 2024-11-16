{
  # TODO make desktop item
  flake.overlays.srm = final: prev: {
    steam-rom-manager = final.callPackage ({
      lib,
      stdenv,
      buildPackages,
      fetchFromGitHub,
      fetchYarnDeps,
      fixup-yarn-lock,
      makeWrapper,
      pkg-config,
      xdg-utils,
      electron,
      nodejs,
      python3,
      sqlite,
      yarn,
      makeDesktopItem,
      copyDesktopItems,
    }: stdenv.mkDerivation rec {
      pname = "steam-rom-manager";
      version = lib.substring 0 7 src.rev;
      src = fetchFromGitHub {
        owner = "schradert";
        repo = "steam-rom-manager";
        rev = "4d05174b0009c9f1ff92d475b290c165cfa629c5";
        hash = "sha256-z8x0G1kafPVEOFYKTK2PH+t65jqUnVwPa41AXMUiKg4=";
      };
      offlineCache = fetchYarnDeps {
        yarnLock = src + "/yarn.lock";
        hash = "sha256-UD2v3jIv41NrKygeHvVI9sWLFRifhIRgpDn1Ef3zhp0=";
      };
      nativeBuildInputs = [
        yarn
        nodejs
        (python3.withPackages (ps: [ps.setuptools]))
        fixup-yarn-lock
        pkg-config
        makeWrapper
      ];
      buildInputs = [sqlite xdg-utils];
      configurePhase = ''
        runHook preConfigure

        export HOME=$(mktemp -d)
        yarn config --offline set yarn-offline-mirror ${offlineCache}
        fixup-yarn-lock yarn.lock
        yarn install --offline --frozen-lockfile --ignore-platform --ignore-scripts --no-progress --non-interactive

        patchShebangs node_modules/

        # Rebuild better-sqlite3 with node-gyp
        mkdir -p "$HOME/.node-gyp/${nodejs.version}"
        echo 9 > "$HOME/.node-gyp/${nodejs.version}/installVersion"
        ln -sfv "${nodejs}/include" "$HOME/.node-gyp/${nodejs.version}"
        export npm_config_nodedir=${nodejs}
        npm_config_node_gyp="${buildPackages.nodejs}/lib/node_modules/npm/node_modules/node-gyp/bin/node-gyp.js" npm rebuild --verbose --sqlite=${sqlite.dev} better-sqlite3

        runHook postConfigure
      '';
      buildPhase = ''
        runHook preBuild

        yarn config --offline set yarn-offline-mirror ${offlineCache}
        yarn --offline build:dist
        yarn --offline electron-builder --dir -c.electronDist=${electron.dist} -c.electronVersion=${electron.version}

        runHook postBuild
      '';
      installPhase = ''
        runHook preInstall

        mkdir -p "$out/share/steam-rom-manager"
        cp -R ./release/*-unpacked/{locales,resources{,.pak}} "$out/share/steam-rom-manager"

        makeWrapper '${electron}/bin/electron' "$out/bin/steam-rom-manager" \
          --add-flags "$out/share/steam-rom-manager/resources/app.asar" \
          --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations}}" \
          --inherit-argv0

        runHook postInstall
      '';
      desktopItems = [
        (makeDesktopItem {
          name = "Steam ROM Manager";
          type = "Application";
          exec = "steam-rom-manager";
          icon = "steam-rom-manager";
          desktopName = "Steam ROM Manager";
          genericName = "Steam ROM Manager";
          categories = ["Game"];
        })
      ];
    }) {};
  };
  canivete.deploy.nixos.homeModules.steam-rom-manager = {config, lib, pkgs, ...}: let
    inherit (lib) attrValues concatStringsSep filterAttrs flatten length flip getExe mapAttrsToList mkAliasOptionModule mkDefault mkEnableOption mkPackageOption mkOption mkIf literalExpression pipe imap1 recursiveUpdate types;
    inherit (types) attrsOf bool float enum listOf submodule path pathInStore str int;
    inherit (config.home) homeDirectory;
    inherit (config.dotfiles.programs.steam) external;
    inherit (external) srm retroarch;
    inherit (pkgs) formats runCommand jq moreutils;
    json = formats.json {};
    userSettings = json.generate "userSettings.json" srm.settings;
    userConfigurations = runCommand "userConfigurations.json" {
      # TODO is is possible to do all of this in one jq call?
      # NOTE from what I could gather, importing json into a running jq program from a dynamic path is not possible
      parsers = json.generate "parsers.json" (pipe external.consoles [
        (filterAttrs (_: console: length console.programs > 0))
        (mapAttrsToList (_: console: attrValues console.parsers))
        flatten
        # Parser IDs are generated when added, so we do the same here
        (imap1 (i: recursiveUpdate {overrides.parserId = builtins.toString i;}))
      ]);
      jq = getExe jq;
      srm = srm.package.src;
      sponge = "${moreutils}/bin/sponge";
    } ''
      echo "[]" > $out
      $jq --compact-output --raw-output '.[] | (.preset, .overrides)' $parsers | while read -r preset; do
          read -r overrides
          preset_file="$srm/files/presets/''${preset%% - *}.json"
          preset_json="$([[ -f $preset_file ]] && $jq --compact-output --arg preset "$preset" '.[$preset] // {}' "$preset_file" || echo "{}")"
          $jq --argjson overrides "$overrides" --argjson preset "$preset_json" '. + [$preset * $overrides]' $out | $sponge $out
      done
    '';
  in {
    options.dotfiles.programs.steam.external = {
      consoles = mkOption {
        type = attrsOf (submodule ({name, config, ...}: {
          options.parsers = mkOption {
            type = attrsOf (submodule ({name, ...}: {
              options.preset = mkOption {
                type = str;
                default = name;
                description = "Preset parser configuration to override";
              };
              options.overrides = mkOption {
                inherit (json) type;
                default = {};
                description = "Preferred settings to override from the preset";
              };
              config.overrides.configTitle = mkDefault name;
            }));
            default = {};
            description = "Parsers to be stored in userConfigurations.json as a list. They will be merged with presets by name if they exist.";
          };
        }));
      };
      srm = mkOption {
        default = {};
        type = submodule {
          imports = [
            (mkAliasOptionModule ["romsDirectory"] ["settings" "environmentVariables" "romsDirectory"])
            (mkAliasOptionModule ["userAccounts"] ["settings" "environmentVariables" "userAccounts"])
          ];
          options.package = mkPackageOption pkgs "steam-rom-manager" {};
          options.settings = mkOption {
            type = submodule {
              freeformType = json.type;
              options = {
                fuzzyMatcher = {
                  # TODO submit issue report and pull request to separate timestamp state from user settings
                  timestamps.check = mkOption {type = int; default = 0;};
                  timestamps.download = mkOption {type = int; default = 0;};
                  verbose = mkEnableOption "fuzzy matching verbose logging";
                  # TODO what does this do?
                  filterProviders = mkEnableOption "" // {default = true;};
                };
                environmentVariables = {
                  steamDirectory = mkOption {
                    type = path;
                    # TODO is this specified somewhere?
                    default = "${homeDirectory}/.steam/steam";
                    description = "Location of steam configuration";
                  };
                  userAccounts = mkOption {
                    type = listOf str;
                    default = [];
                    description = "Steam usernames to associate ROMs with";
                  };
                  romsDirectory = mkOption {
                    type = path;
                    default = "${homeDirectory}/Games/ROMs";
                    description = "Global location where all ROMs are located";
                  };
                  retroarchPath = mkOption {
                    type = pathInStore;
                    default = getExe retroarch.package;
                    description = "Retroarch executable";
                  };
                  localImagesDirectory = mkOption {
                    # TODO should I do mapAttrsRecursive when generating json to turn null into "" when I don't want to specify?
                    type = str;
                    default = "";
                    description = "Global location for game image assets";
                  };
                  raCoresDirectory = mkOption {
                    type = pathInStore;
                    default = "${retroarch.package}/lib/retroarch/cores";
                    description = "Dynamic libretro libraries for emulation cores";
                  };
                };
                # TODO how to generate this?
                language = mkOption {
                  type = str;
                  default = "en-US";
                  description = "User-facing language";
                };
                theme = mkOption {
                  type = enum ["Deck" "Classic" "EmuDeck"];
                  default = "Deck";
                  description = "GUI theme";
                };
                emudeckInstall = mkOption {
                  type = bool;
                  default = false;
                  readOnly = true;
                  description = "EmuDeck will never be managing this";
                };
                enabledProviders = mkOption {
                  type = listOf (enum ["sgdb" "steamCDN"]);
                  default = ["sgdb" "steamCDN"];
                  description = "Online image providers for ROMs";
                };
                batchDownloadSize = mkOption {
                  type = int;
                  default = 50;
                  description = "Number of images to download at once";
                };
                dnsServers = mkOption {
                  type = listOf str;
                  default = [];
                  description = "DNS servers to resolve online providers";
                };
                previewSettings = {
                  retrieveCurrentSteamImages = mkEnableOption "fetching most recent steam images" // {default = true;};
                  disableCategories = mkEnableOption "disabling of steam categorization";
                  deleteDisabledShortcuts = mkEnableOption "removing disabled shortcuts automatically";
                  imageZoomPercentage = mkOption {
                    type = float;
                    default = 35.25;
                    description = "Default zoom ratio of image assets in preview";
                  };
                  imageLoadStrategy = mkOption {
                    type = enum ["loadPre" "loadNormal" "loadLazy"];
                    default = "loadLazy";
                    description = "When to load artwork (normal preloads just the first image, pre preloads all of them)";
                  };
                  hideUserAccount = mkEnableOption "hiding user that uploaded image from preview";
                  # TODO mine was empty so can this be null??
                  # TODO what does this do?
                  imageTypes = mkOption {
                    type = listOf str;
                    default = [];
                    description = "";
                  };
                };
                autoKillSteam = mkEnableOption "killing steam when games refresh";
                autoRestartSteam = mkEnableOption "starting steam after killing it from game refresh";
                # TODO what does these do?
                autoUpdate = mkEnableOption "" // {default = true;};
                offlineMode = mkEnableOption "";
                navigationWidth = mkOption {
                  type = int;
                  default = 0;
                  description = "";
                };
                clearLogOnTest = mkEnableOption "";
                version = mkOption {
                  type = int;
                  default = 10;
                  description = "";
                };
              };
            };
            description = "Contents of userSettings.json";
            example = literalExpression "{ environmentVariables.steamDirectory = \"/home/user/.steam/steam\"; }";
          };
        };
      };
    };
    config = mkIf external.enable {
      # TODO get parser definitions to work
      # NOTE open enhancement request: https://github.com/SteamGridDB/steam-rom-manager/issues/720
      # TODO how can I prefix these commands with a virtual headless display
      # TODO is making it editable better than using home.file?
      # NOTE userSettings needs to precede init to start non-interactive, but userConfigurations is overwritten on init
      home.activation.steam-rom-manager = lib.hm.dag.entryAfter ["writeBoundary"] ''
        userData="${homeDirectory}/.config/steam-rom-manager/userData"
        install -D --mode 644 ${userSettings} "$userData/userSettings.json"
        # install -D --mode 644 ${userConfigurations} "$userData/userConfigurations.json"
        # ${getExe srm.package} add || true
      '';
    };
  };
}
