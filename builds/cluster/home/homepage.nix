{
  # TODO find a good kubernetes deployment strategy
  # NOTE https://github.com/gethomepage/homepage
  # NOTE https://github.com/NixOS/nixpkgs/blob/nixos-unstable/nixos/modules/services/misc/homepage-dashboard.nix
  perSystem.canivete.arion.modules.homepage-dashboard.services.homepage-dashboard = {
    nixos.configuration.services.homepage-dashboard = {
      enable = true;
      # TODO how do I configure this?!
      # NOTE https://gethomepage.dev/latest/configs/docker/
      # docker = {};
      # NOTE https://gethomepage.dev/latest/configs/service-widgets/
      # widgets = [{}];
      # NOTE https://gethomepage.dev/latest/configs/settings/
      # settings = {};
      # NOTE https://gethomepage.dev/latest/configs/services/
      # services = [{}];
      # NOTE https://gethomepage.dev/latest/configs/custom-css-js/
      # customJS = "";
      # customCSS = "";
      # NOTE https://gethomepage.dev/latest/configs/bookmarks/
      # bookmarks = [{}];
      # NOTE https://gethomepage.dev/latest/configs/kubernetes/
      # kubernetes = {};
      # TODO SECRETS
      # NOTE https://gethomepage.dev/latest/installation/docker/#using-environment-secrets
      # environmentFile = "";
    };
    nixos.useSystemd = true;
  };
}
