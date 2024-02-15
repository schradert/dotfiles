{inputs, nix, ...}: with nix; {
  options.flake = mkSubmoduleOptions {
    terranixModules = mkOpenModuleOption {
      description = mkDoc "Terranix modules";
    };
  };
  config.perSystem = {pkgs, self', system, ...}: {
    packages.terranixConfiguration = inputs.terranix.lib.terranixConfiguration {
      inherit pkgs system;
      modules = attrValues inputs.self.terranixModules;
    };
    packages.terranix-deploy = pkgs.writeShellApplication {
      name = "terranix-deploy";
      text = ''
        root="$(${pkgs.git}/bin/git rev-parse --show-toplevel)"
        cp -f ${self'.packages.terranixConfiguration} "$root/config.tf.json"
        ${pkgs.terraform}/bin/terraform -chdir="$root" init
        ${pkgs.terraform}/bin/terraform -chdir="$root" "''${@:-apply}"
      '';
    };
    devShells.terraform = pkgs.mkShell {
      packages = with pkgs; [terraform terranix];
    };
  };
}
