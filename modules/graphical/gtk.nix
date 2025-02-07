{
  canivete.deploy.nixos.homeModules.gtk = {
    config,
    lib,
    perSystem,
    pkgs,
    ...
  }: let
    inherit (config.dotfiles.graphical) gtk;
    inherit (lib) mkEnableOption mkOption types mkIf;
    inherit (types) attrsOf submodule package str;
    inherit (pkgs) stdenvNoCC fetchFromGitHub gnused rsync gtk-engine-murrine unstableGitUpdater noto-fonts papirus-maia-icon-theme formats capitaine-cursors gtk3 gsettings-desktop-schemas writeShellApplication wpgtk gum;
    theme = stdenvNoCC.mkDerivation rec {
      pname = "linea-nord-color";
      version = "0.1";
      src = fetchFromGitHub {
        owner = "deviantfero";
        repo = "wpgtk-templates";
        rev = "4119a9afb27acf9e231c211cdfd12992c318499e";
        hash = "sha256-LKIVasIO6ZjuRnY5NEj4NrtHchW8lafsnfh1IiEcoR0=";
      };
      sourceRoot = "source/${pname}";
      # TODO there is probably a better way to do this
      patchPhase = "sed -i '1i\\@import url(\"file:///home/tristan/.config/wpg/templates/gtk.css\");' dark.css.base";
      nativeBuildInputs = [gnused rsync];
      propagatedUserEnvPkgs = [gtk-engine-murrine];
      installPhase = "mkdir -p $out/share && cp -R . $out/share/${pname}";
      passthru.updateScript = unstableGitUpdater {tagPrefix = "v";};
    };
  in {
    options.dotfiles.graphical.gtk = {
      enable = mkEnableOption "GTK centralized configuration" // {default = config.dotfiles.graphical.hyprland.enable;};
      themes = mkOption {
        default = {};
        type = let
          theme = submodule {
            options.name = mkOption {type = str;};
            options.package = mkOption {type = package;};
          };
        in
          attrsOf (submodule {
            options = {
              wallpaper = theme;
              font = theme;
              icon = theme;
              cursor = theme;
              inherit theme;
            };
          });
      };
      switcher = mkOption {
        type = package;
        default = writeShellApplication {
          name = "theme";
          runtimeInputs = [wpgtk gum config.dotfiles.services.swww.package];
          runtimeEnv.DIRECTORY = config.dotfiles.services.swww.config.wallpapers_dir;
          text = ''
            readarray -d "" wallpapers < <(find "$DIRECTORY" -type f -exec bash -c 'printf "$(basename "$1")\0"' _ {} \;)
            if [[ -n ''${1-} ]]; then
                if [[ $1 == --list ]]; then
                    for wallpaper in "''${wallpapers[@]}"; do
                        echo "$DIRECTORY/$wallpaper"
                    done
                    exit 0
                fi
                wallpaper="$1"
            else
                wallpaper="$(gum choose "''${wallpapers[@]}")"
            fi
            if [[ -z $wallpaper || ! -f $DIRECTORY/$wallpaper ]]; then
                gum log --structured --level error "No valid file specified. Aborting..." name "$wallpaper"
                exit 1
            fi
            swww img --transition-type simple --transition-fps 60 "$DIRECTORY/$wallpaper"
            wpg -a "$DIRECTORY/$wallpaper" -n
            wpg -A "$wallpaper" -n
            wpg -s "$wallpaper" -n
          '';
        };
      };
      switcher2 = mkOption {
        type = package;
        default = writeShellApplication {
          name = "theme2";
          # NOTE unstable gum seems to have a broken table
          runtimeInputs = [
            wpgtk
            pkgs.csvtool
            pkgs.gnused
            perSystem.inputs'.nixpkgs-stable.packages.gum
            config.dotfiles.services.swww.package
          ];
          runtimeEnv.DIRECTORY = config.dotfiles.services.swww.config.wallpapers_dir;
          text = ''
            theme="$(gum table < <(jq --from-file "$TABLE_FILTER" "$THEMES_JSON") | csvtool 1 - | sed 's/^"\|"$//g')
            if [[ -z $theme ]]; then
                gum log --level error "No theme specified. Aborting..."
                exit 1
            fi
            jq --arg theme "$theme" --from-file "$FILES_FILTER" "$THEMES_JSON"
            swww img --transition-type simple --transition-fps 60 "$DIRECTORY/$wallpaper"
            wpg -a "$DIRECTORY/$wallpaper" -n
            wpg -A "$wallpaper" -n
            wpg -s "$wallpaper" -n
          '';
        };
      };
    };
    config = mkIf gtk.enable {
      # TODO set XCURSOR_THEME, XCURSOR_SIZE, use "hyprctl setcursor", and "dconf write /org/gnome/desktop/interface/cursor-theme 'THEME'"
      # TODO create hyprcursor themes for all the xcursor themes I want to use (Bibata - bibata-cursors)
      # TODO catpuccin
      # TODO nord https://github.com/nordtheme/vim
      # NOTE https://github.com/hyprwm/hyprcursor/tree/main/hyprcursor-util
      #       themes = {
      #         "Linea Nord Color" = {
      #           wallpaper.name = "Fog";
      #           wallpaper.package = ./themes/fog.jpg;
      #           font.name = "Noto Sans";
      #           font.package = noto-fonts;
      #           icon.name = "Papirus-Dark-Maia";
      #           icon.package = papirus-maia-icon-theme;
      #           cursor.name = "Capitaine Cursors - White";
      #           cursor.package = capitaine-cursors;
      #           theme.name = "linea-nord-color";
      #           theme.package = theme;
      #         };
      #         Dracula = {
      #           wallpaper.name = "Dracula";
      #           wallpaper.package = ./themes/dracula.png;
      #           font.name = "Slime and Blood";
      #           font.package = runCommand "slime-and-blood" {
      #             src = fetchurl {
      #               url = "https://www.1001fonts.com/download/font/slime-and-blood.regular.ttf";
      #               hash = "";
      #             };
      #           } "install --target-directory $out/share/fonts/slime-and-blood -D $src";
      #           icon.name = "Dracula";
      #           icon.package = dracula-icon-theme;
      #           cursor.name = "Dracula-cursors";
      #           cursor.package = dracula-theme;
      #           theme.name = "Dracula";
      #           theme.package = dracula-theme;
      #         };
      #         # TODO pokemon, samurai, forest, aquatic themes!
      #         # TODO automatic theme switch script
      #         # TODO light and dark versions of each theme
      #       };
      # TODO move to dynamic icon, fonts, and cursor themes
      gtk = {
        enable = true;
        font.name = "Noto Sans";
        font.package = noto-fonts;
        iconTheme.name = "Papirus-Dark-Maia";
        iconTheme.package = papirus-maia-icon-theme;
        theme.name = "linea-nord-color";
        theme.package = theme;
        gtk3.extraConfig = {
          gtk-application-prefer-dark-theme = true;
          gtk-key-theme-name = "Default";
          gtk-icon-theme-name = "Papirus-Dark-Maia";
          gtk-cursor-theme-name = "Capitaine Cursors - White";
          # gtk-cursor-theme-name = "breeze_cursors";
          # gtk-cursor-theme-size = 24;
          # gtk-decoration-layout = "icon:minimize,maximize,close";
          # gtk-enable-animations = true;
          # gtk-font-name = "Noto Sans,  10";
          # gtk-icon-theme-name = "breeze-dark";
          # gtk-modules = "colorreload-gtk-module";
          # gtk-primary-button-warps-slider = true;
          # gtk-sound-theme-name = "ocean";
          # gtk-xft-dpi = 122880;
          # gtk.css has @import 'colors.css';
          # colors.css defines many different colors and properties
        };
      };
      # TODO can this be converted into other GTK options?
      home.file.".icons/default".source = "${capitaine-cursors}/share/icons/capitaine-cursors-white";
      home.packages = [gtk.switcher wpgtk];
      home.sessionVariables.XCURSOR_SIZE = 16;
      home.sessionVariables.XCURSOR_THEME = "Capitaine Cursors - White";
      xdg.configFile."wpg/templates/gtk.css.base".source = theme + "/share/${theme.pname}/dark.css.base";
      xdg.configFile."wpg/wpg.conf".source = (formats.ini {}).generate "wpg.conf" {
        settings = {
          set_wallpaper = false;
          gtk = true;
          active = 0;
          light_theme = false;
          editor = "vim";
          execute_cmd = false;
          command = "";
          backend = "wal";
          alpha = 100;
          smart_sort = true;
          auto_adjust = true;
          # old
          # editor = "urxvt -e vim";
          # command = "urxvt -e echo hi";
          # reload = true;
        };
      };
      xdg.mimeApps.enable = true;
      xdg.mimeApps.defaultApplications = {
        "inode/directory" = ["Thunar.desktop"];
        "image/png" = ["imv.desktop"];
        "image/jpeg" = ["imv.desktop"];
        # old (also under added associations)
        # "x-scheme-handler/bitwarden" = ["Bitwarden.desktop"];
      };
      xdg.systemDirs.data = [
        "${gtk3}/share/gsettings-schemas/${gtk3.name}"
        "${gsettings-desktop-schemas}/share/gsettings-schemas/${gsettings-desktop-schemas.name}"
      ];
    };
  };
}
