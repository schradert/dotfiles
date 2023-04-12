[
  (self: super: {
    tmux = super.tmux.overrideAttrs (_: {
      version = "unstable-2023-04-06";
      src = super.fetchFromGitHub {
        owner = "tmux";
        repo = "tmux";
        rev = "b9524f5b72d16bd634fc47ad1a4a9d3240bd4370";
        sha256 = "7jvmeMipZcNMqFloMuSgPwKowNqWC1J8/++ha6H/D1M=";
      };
      patches = [];
    });
    tmuxPlugins = super.tmuxPlugins // {
      dracula = super.tmuxPlugins.dracula.overrideAttrs (_: {
        version = "unstable-2023-04-04";
        src = super.fetchFromGitHub {
          owner = "dracula";
          repo = "tmux";
          rev = "b346d1030696620154309f71d5b14bc657294a98";
          sha256 = "89S8LHTx2gYWj+Ejws5f6YRQgoj0rYE7ITtGtZibl30=";
        };
      });
    };
  })
]
