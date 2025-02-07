{
  # TODO configure more! https://github.com/xxh/xxh
  canivete.deploy.system.homeModules.xxh = {pkgs, ...}: {
    home.packages = [pkgs.xxh];
  };
}
