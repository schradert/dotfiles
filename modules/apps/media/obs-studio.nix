{
  # TODO deploy on kubernetes with web interface https://github.com/Niek/obs-web
  dotfiles.nixos = {
    config,
    lib,
    pkgs,
    ...
  }: {
    options.dotfiles.programs.obs-studio.enable = lib.mkEnableOption "OBS Studio";
    config = lib.mkIf config.dotfiles.programs.obs-studio.enable {
      boot.extraModprobeConfig = ''
        options v4l2loopback devices=1 video_nr=0 card_label="OBS Cam" exclusive_caps=1
      '';
      boot.extraModulePackages = [config.boot.kernelPackages.v4l2loopback];
      boot.kernelModules = ["v4l2loopback"];
      environment.systemPackages = [pkgs.v4l-utils];
      home-manager.sharedModules = [
        {
          programs.obs-studio = {
            enable = true;
            plugins = with pkgs.obs-studio-plugins; [
              droidcam-obs
              # wlrobs
              # waveform
              # obs-vkcapture
              # obs-vintage-filter
              # obs-vertical-canvas
              # # TODO should I use gstreamer or ffmpeg for VAAPI support?
              # # TODO set up VAAPI support (VDPAU if I ever go nvidia)
              # # NOTE https://nixos.wiki/wiki/Accelerated_Video_Playback
              # # obs-aapi
              # obs-tuna
              # # TODO follow https://github.com/NixOS/nixpkgs/pull/369369
              # # obs-transition-table
              # obs-text-pthread
              # obs-teleport
              # obs-source-switcher
              # # TODO monitor obs-source-record for stability
              # # TODO try to build https://github.com/OPENSPHERE-Inc/branch-output instead
              # # TODO is this a replacement for obs-multi-rtmp
              # # obs-source-record
              # # obs-branch-output
              # obs-source-clone
              # obs-shaderfilter
              # obs-scale-to-sound
              # obs-pipewire-audio-capture
              # obs-mute-filter
              # obs-move-transition
              # obs-livesplit-one
              # obs-hyperion
              # obs-gstreamer
              # obs-gradient-source
              # obs-freeze-filter
              # obs-composite-blur
              # obs-backgroundremoval
              # obs-3d-effect
              # # TODO which is better: input-overlay vs https://github.com/AlynxZhou/showmethekey
              # # NOTE https://github.com/mulaRahul/keyviz
              # input-overlay
              # advanced-scene-switcher
            ];
          };
        }
      ];
      # NOTE v4l2loopback hardening support won't be available until 31.1
      nixpkgs.overlays = [
        (final: prev: {
          obs-studio = prev.obs-studio.overrideAttrs (old: {
            version = "31.1.0-rc1";
            src = old.src.override {
              hash = "sha256-z6BMgddmq3+IsVkt0a/FP+gShvGi1tI6qBbJlAcHgW8=";
            };
            nativeBuildInputs = old.nativeBuildInputs ++ [final.extra-cmake-modules];
          });
        })
      ];
      # TODO declarative pipewire config of a VAC loopback to use Droidcam OBS monitoring audio as mic input
      # NOTE pactl module-null-sink ...
      # NOTE pactl module-remap-source ...
    };
  };
}
