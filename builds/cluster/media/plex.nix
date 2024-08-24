{
  # TODO nodeAffinity for bonobo, chinchilla, dingo, and axolotl
  # https://github.com/Kometa-Team/ImageMaid
  # https://www.reddit.com/r/PleX/comments/143cviv/plex_image_cleanup_clean_up_your_metadata_with/
  # [ ] [plex-auto-languages](https://github.com/bjw-s/home-ops/blob/main/kubernetes/main/apps/media/plex/plex-auto-languages/helmrelease.yaml)
  # https://github.com/RemiRigal/Plex-Auto-Languages
  # https://github.com/blacktwin/JBOPS
  perSystem.canivete.arion.modules.plex.services.plex = {
    nixos.configuration = {pkgs, ...}: {
      services.plex = {
        enable = true;
        openFirewall = true;
        extraPlugins = [
          (builtins.path {
            name = "Audnexus.bundle";
            path = pkgs.fetchFromGitHub {
              owner = "djdembeck";
              repo = "Audnexus.bundle";
              rev = "v1.3.2";
              hash = "";
            };
          })
        ];
        extraScanners = [
          (pkgs.fetchFromGitHub {
            owner = "ZeroQI";
            repo = "Absolute-Series-Scanner";
            rev = "048e8001a525ba1c04afda2aa2005feb74709eb8";
            hash = "";
          })
        ];
      };
      services.tautulli.enable = true;
      services.tautulli.openFirewall = true;
    };
    nixos.useSystemd = true;
  };
}
