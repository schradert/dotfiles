{
  canivete.deploy.system.homeModules.wezterm = {
    config,
    lib,
    perSystem,
    pkgs,
    ...
  }: let
    inherit (lib) mkEnableOption mkIf mkMerge;
  in {
    options.dotfiles.programs.wezterm.enable = mkEnableOption "Wezterm";
    config = mkIf config.dotfiles.programs.wezterm.enable (mkMerge [
      {
        programs.wezterm = {
          enable = true;
          package = perSystem.inputs'.wezterm.packages.default;
          # Prevent WezTerm from overriding SSH_AUTH_SOCK from ssh-agent service
          extraConfig = "return {mux_enable_ssh_agent = false}";
        };
      }
      (mkIf pkgs.stdenv.isDarwin {
        launchd.agents.wezterm = {
          enable = true;
          config.RunAtLoad = true;
          config.KeepAlive.Crashed = true;
          config.Program = "${config.programs.wezterm.package}/Applications/WezTerm.app/Contents/MacOS/WezTerm";
        };
      })
      (mkIf config.dotfiles.graphical.hyprland.enable {
        wayland.windowManager.hyprland.settings."$terminal" = "wezterm";
      })
    ]);
  };
}
# TODO add snippet to copy everything
#{
#key = 'c',
#mods = 'CTRL|SHIFT',
#action = wezterm.action_callback(function(win, pane)
#local lines = pane:get_lines_as_text(1000000) -- same as `scrollback_lines`
#win:copy_to_clipboard(lines, 'Clipboard')
#end),
#},
#local function copyAll(win,pane)  -- copy all text in a pane (except for bottom prompt in Xonsh)
#  local prompt_bottom_offset = 0
#  local proc = pane:get_foreground_process_info()
#  local name, binpath, arg = proc.name,proc.executable,proc.argv
#  local isXonsh = sh.isXonsh(arg)
#  if isXonsh then
#    if os.getenv("BOTTOM_TOOLBAR") then
#      prompt_bottom_offset = 2 -- exclude the main + bottom prompts
#    else
#      prompt_bottom_offset = 1 -- exclude the main          prompt
#  end end
#
#  local dims = pane:get_dimensions()
#  local txt  = pane:get_text_from_region(0
#    , dims.scrollback_top              , 0
#    , dims.scrollback_top + dims.scrollback_rows - prompt_bottom_offset)
#  win:copy_to_clipboard(txt:match('^%s*(.-)%s*$')) -- trim leading and trailing whitespace
#end
