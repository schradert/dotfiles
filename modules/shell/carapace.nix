{
  # TODO https://github.com/carapace-sh/carapace-bin
  canivete.deploy.system.homeModules.carapace = {pkgs, ...}: {
    home.packages = [pkgs.carapace];
  };
}
