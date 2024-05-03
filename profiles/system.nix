{nix, ...}:
with nix; {
  options.flake = mkSubmoduleOptions {
    systemModules = mkModulesOption {
      description = mdDoc "Modules common to system config tools (nixos, nix-darwin, nix-on-droid)";
    };
  };
  config = {
    flake.systemModules.default.nix.extraOptions = ''
      experimental-features = nix-command flakes
    '';
    canivete.pkgs.config.allowUnfreePredicate = pkg: elem (getName pkg) ["android-studio-stable" "discord" "raycast" "slack" "spotify" "beeper"];
  };
}
