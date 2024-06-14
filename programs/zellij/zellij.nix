{
  flake.homeModules.zellij = {pkgs, ...}: {
    programs.zellij = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        theme = "dracula";
        layout_dir = toString ./layouts;
      };
    };
    xdg.configFile."zellij/themes/dracula.kdl".source = let
      source = pkgs.fetchFromGitHub {
        owner = "dracula";
        repo = "zellij";
        rev = "master";
        hash = "sha256-Sqj9EhDhr5Kv9x9GwfPUvNOQocGzbVScVSGnR0/yf7Q=";
      };
    in "${source}/dracula.kdl";
  };
}
