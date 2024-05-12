{
  perSystem = {pkgs, ...}: {
    canivete.pre-commit = {
      languages.shell.enable = true;
      settings = {
        excludes = ["old/.+" ".canivete/sops/default.yaml" ".canivete/sops/tristan"];
        # TODO extract these tool configurations into options
        hooks.lychee.settings.configPath = toString (pkgs.writers.writeTOML "lychee.toml" {exclude_path = ["programs/emacs/config.org"];});
        # Used in vim configuration
        hooks.typos.settings.configPath = toString (pkgs.writers.writeTOML "_typos.toml" {default.extend-words.enew = "enew";});
        # zsh not really supported by shfmt
        hooks.shfmt.excludes = ["programs/zsh/.p10k.zsh"];
      };
    };
  };
}
