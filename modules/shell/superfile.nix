{
  canivete.deploy.system.homeModules.superfile = {
    config,
    lib,
    pkgs,
    perSystem,
    ...
  }: let
    inherit (config.dotfiles.programs) superfile;
    inherit (lib) mkEnableOption mkOption mkPackageOption mkIf mkMerge;
    toml = pkgs.formats.toml {};
  in {
    options.dotfiles.programs.superfile = {
      enable = mkEnableOption "superfile file manager";
      package = mkPackageOption perSystem.inputs'.superfile.packages "superfile" {};
      config = mkOption {
        inherit (toml) type;
        default = {};
      };
      hotkeys = mkOption {
        inherit (toml) type;
        default = {};
      };
    };
    config = mkIf superfile.enable {
      dotfiles.programs.superfile.config.metadata = true;
      home.packages = [superfile.package pkgs.exiftool];
      xdg.configFile = mkMerge [
        (mkIf (superfile.config != {}) {"superfile/config.toml".source = toml.generate "superfile.config.toml" superfile.config;})
        (mkIf (superfile.hotkeys != {}) {"superfile/hotkeys.toml".source = toml.generate "superfile.hotkeys.toml" superfile.hotkeys;})
      ];
    };
  };
  canivete.deploy.nixos.homeModules.superfile = {pkgs, ...}: {
    dotfiles.programs.superfile = {
      enable = true;
      config.theme = "matugen";
    };
    dotfiles.programs.matugen.programs.matugen.templates.superfile = {
      output_path = "~/.config/superfile/theme/matugen.toml";
      input_path = (pkgs.formats.toml {}).generate "superfile.theme.toml" {
        code_syntax_highlight = "dracula";
        file_panel_border = "{{colors.outline.default.hex}}";
        sidebar_border = "{{colors.outline.default.hex}}";
        footer_border = "{{colors.outline.default.hex}}";
        file_panel_border_active = "{{colors.tertiary.default.hex}}";
        sidebar_border_active = "{{colors.tertiary.default.hex}}";
        footer_border_active = "{{colors.tertiary.default.hex}}";
        modal_border_active = "{{colors.tertiary.default.hex}}";
        full_screen_bg = "{{colors.primary.default.hex}}";
        file_panel_bg = "{{colors.primary.default.hex}}";
        sidebar_bg = "{{colors.primary.default.hex}}";
        footer_bg = "{{colors.primary.default.hex}}";
        modal_bg = "{{colors.primary.default.hex}}";
        full_screen_fg = "{{colors.on_primary.default.hex}}";
        file_panel_fg = "{{colors.on_primary.default.hex}}";
        sidebar_fg = "{{colors.on_primary.default.hex}}";
        footer_fg = "{{colors.on_primary.default.hex}}";
        modal_fg = "{{colors.on_primary.default.hex}}";
        cursor = "{{colors.surface_container.default.hex}}";
        correct = "{{colors.primary_container.default.hex}}";
        error = "{{colors.error.default.hex}}";
        hint = "{{colors.tertiary_container.default.hex}}";
        cancel = "{{colors.secondary_container.default.hex}}";
        gradient_color = ["{{colors.on_surface.default.hex}}" "{{colors.outline_variant.default.hex}}"];
        file_panel_top_directory_icon = "{{colors.tertiary_container.default.hex}}";
        file_panel_top_path = "{{colors.on_tertiary_container.default.hex}}";
        file_panel_item_selected_fg = "{{colors.on_secondary.default.hex}}";
        file_panel_item_selected_bg = "{{colors.secondary.default.hex}}";
        sidebar_title = "{{colors.on_tertiary_container.default.hex}}";
        sidebar_item_selected_fg = "{{colors.on_secondary.default.hex}}";
        sidebar_item_selected_bg = "{{colors.secondary.default.hex}}";
        sidebar_divider = "{{colors.outline.default.hex}}";
        modal_cancel_fg = "{{colors.on_secondary_container.default.hex}}";
        modal_cancel_bg = "{{colors.secondary_container.default.hex}}";
        modal_confirm_fg = "{{colors.on_primary_container.default.hex}}";
        modal_confirm_bg = "{{colors.primary_container.default.hex}}";
        help_menu_hotkey = "{{colors.tertiary_container.default.hex}}";
        help_menu_title = "{{colors.on_tertiary_container.default.hex}}";
      };
    };
  };
}
