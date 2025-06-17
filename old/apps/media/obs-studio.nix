{
  # TODO deploy on kubernetes with web interface https://github.com/Niek/obs-web
  dotfiles.home-manager = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) mkEnableOption mkIf;
  in {
    options.dotfiles.programs.obs-studio.enable = mkEnableOption "obs-studio";
    config = mkIf config.dotfiles.programs.obs-studio.enable {
      programs.obs-studio.enable = true;
      programs.obs-studio.plugins = with pkgs.obs-studio-plugins; [
        wlrobs
        waveform
        obs-vkcapture
        obs-vintage-filter
        obs-vertical-canvas
        # TODO should I use gstreamer or ffmpeg for VAAPI support?
        # TODO set up VAAPI support (VDPAU if I ever go nvidia)
        # NOTE https://nixos.wiki/wiki/Accelerated_Video_Playback
        # obs-aapi
        obs-tuna
        # TODO follow https://github.com/NixOS/nixpkgs/pull/369369
        # obs-transition-table
        obs-text-pthread
        obs-teleport
        obs-source-switcher
        # TODO monitor obs-source-record for stability
        # TODO try to build https://github.com/OPENSPHERE-Inc/branch-output instead
        # TODO is this a replacement for obs-multi-rtmp
        # obs-source-record
        # obs-branch-output
        obs-source-clone
        obs-shaderfilter
        obs-scale-to-sound
        obs-pipewire-audio-capture
        obs-mute-filter
        obs-move-transition
        obs-livesplit-one
        obs-hyperion
        obs-gstreamer
        obs-gradient-source
        obs-freeze-filter
        obs-composite-blur
        obs-backgroundremoval
        obs-3d-effect
        # TODO which is better: input-overlay vs https://github.com/AlynxZhou/showmethekey
        # NOTE https://github.com/mulaRahul/keyviz
        input-overlay
        droidcam-obs
        advanced-scene-switcher
      ];
    };
  };
}
