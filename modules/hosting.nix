{nix, ...}:
with nix; {
  options.dotfiles.domain = mkOption {
    type = strMatching "^[a-z0-9\-]+\.[a-z]{2,}$";
    description = "Base domain for exposing nodes and services";
  };
}
