{
  # TODO infinite recursion
  # flake.overlays.yazi = inputs.yazi.overlays.default;
  # TODO initLua
  # TODO keymap
  # TODO plugins
  # TODO settings
  dotfiles.home-manager = {
    config,
    lib,
    pkgs,
    ...
  }: {
    dotfiles.programs.matugen.templates = lib.mkIf config.programs.yazi.enable {
      yazi.output_path = "~/.config/yazi/theme.toml";
      yazi.input_path = (pkgs.formats.toml {}).generate "yazi.theme.toml" {
        manager = {
          cwd.fg = "{{colors.secondary.default.hex}}";
          cwd.bold = true;
          hovered.fg = "{{colors.on_primary_container.default.hex}}";
          hovered.bg = "{{colors.primary_container.default.hex}}";
          preview_hovered.underline = true;
          preview_hovered.bold = true;
        };
        status = {
          separator_open = "";
          separator_close = "";
          separator_style.fg = "{{colors.on_primary_container.default.hex}}";
          separator_style.bg = "{{colors.primary_container.default.hex}}";
          mode_normal.fg = "{{colors.on_primary.default.hex}}";
          mode_normal.bg = "{{colors.primary.default.hex}}";
          mode_normal.bold = true;
          mode_select.fg = "{{colors.on_secondary.default.hex}}";
          mode_select.bg = "{{colors.secondary.default.hex}}";
          mode_select.bold = true;
          mode_unset.fg = "{{colors.on_tertiary.default.hex}}";
          mode_unset.bg = "{{colors.tertiary.default.hex}}";
          mode_unset.bold = true;
        };
        which = {
          mask.bg = "{{colors.surface_container.default.hex}}";
          cand.fg = "{{colors.primary.default.hex}}";
          desc.fg = "{{colors.secondary.default.hex}}";
          separator = " . ";
          separator_style.fg = "{{colors.tertiary.default.hex}}";
        };
        filetype.rules = [
          {
            mime = "image/*";
            fg = "{{colors.secondary.default.hex}}";
          }
          {
            mime = "video/*";
            fg = "{{colors.tertiary.default.hex}}";
          }
          {
            mime = "audio/*";
            fg = "{{colors.tertiary.default.hex}}";
          }
          {
            mime = "application/zip";
            fg = "{{colors.error.default.hex}}";
          }
          {
            mime = "application/gzip";
            fg = "{{colors.error.default.hex}}";
          }
          {
            mime = "application/x-tar";
            fg = "{{colors.error.default.hex}}";
          }
          {
            mime = "application/x-bzip";
            fg = "{{colors.error.default.hex}}";
          }
          {
            mime = "application/x-bzip2";
            fg = "{{colors.error.default.hex}}";
          }
          {
            mime = "application/x-7z-compressed";
            fg = "{{colors.error.default.hex}}";
          }
          {
            mime = "application/x-rar";
            fg = "{{colors.error.default.hex}}";
          }
          {
            mime = "*";
            fg = "{{colors.primary.default.hex}}";
            bold = true;
          }
          {
            mime = "*/";
            fg = "{{colors.secondary.default.hex}}";
            bold = true;
          }
        ];
      };
    };
  };
}
