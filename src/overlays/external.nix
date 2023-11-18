final: prev: {
   tmux = prev.tmux.overrideAttrs (_: {
    version = "unstable-2023-04-06";
    src = prev.fetchFromGitHub {
      owner = "tmux";
      repo = "tmux";
      rev = "b9524f5b72d16bd634fc47ad1a4a9d3240bd4370";
      sha256 = "7jvmeMipZcNMqFloMuSgPwKowNqWC1J8/++ha6H/D1M=";
    };
    patches = [];
  });
  tmuxPlugins = prev.tmuxPlugins // {
    dracula = prev.tmuxPlugins.dracula.overrideAttrs (_: {
      version = "unstable-2023-04-04";
      src = prev.fetchFromGitHub {
        owner = "dracula";
        repo = "tmux";
        rev = "b346d1030696620154309f71d5b14bc657294a98";
        sha256 = "89S8LHTx2gYWj+Ejws5f6YRQgoj0rYE7ITtGtZibl30=";
      };
    });
  };
  # Upgrading sops because: https://github.com/getsops/sops/issues/1263
}
