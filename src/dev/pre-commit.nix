{inputs, ...}: {
  imports = [inputs.pre-commit-hooks-nix.flakeModule];
  perSystem = {
    config,
    pkgs,
    ...
  }: {
    pre-commit.settings.default_stages = ["push" "manual"];
    pre-commit.settings.hooks = {
      gitleaks.enable = true;
      gitleaks.entry = "${pkgs.gitleaks}/bin/gitleaks protect --redact";
      alejandra.enable = true;
      shellcheck.enable = true;
    };
    devShells.pre-commit = pkgs.mkShell {
      inputsFrom = [config.pre-commit.devShell];
      packages = with pkgs; [alejandra gitleaks shellcheck];
    };
  };
}
