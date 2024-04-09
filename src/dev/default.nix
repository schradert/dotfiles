{
  perSystem = {pkgs, ...}: {
    canivete.pre-commit.shell.enable = true;
    pre-commit.settings = {
      excludes = ["old/.+" "src/dev/sops/default.yaml" "src/dev/sops/tristan"];
      # TODO extract these tool configurations into options
      hooks.lychee.settings.configPath = toString (pkgs.writers.writeTOML "lychee.toml" {exclude_path = ["src/emacs/config.org"];});
      # Used in vim configuration
      hooks.typos.settings.configPath = toString (pkgs.writers.writeTOML "_typos.toml" {default.extend-words.enew = "enew";});
      # zsh not really supported by shfmt
      hooks.shfmt.excludes = ["src/zsh/.p10k.zsh"];
    };
  };
}
