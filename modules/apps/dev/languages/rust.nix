{
  dotfiles.home-manager = {
    config,
    lib,
    pkgs,
    ...
  }: {
    options.dotfiles.programs.rust.enable = lib.mkEnableOption "rust";
    config = lib.mkIf config.dotfiles.programs.rust.enable {
      home.sessionVariables.CARGO_HOME = "${config.xdg.dataHome}/cargo";
      programs.vim.plugins = [pkgs.vimPlugins.rust-vim];
      programs.doom-emacs = {
        extraBinPackages = with pkgs; [cargo rust-analyzer rustc];
        tangle.init.lang.rust = ["+lsp" "+tree-sitter"];
        tangle.config = ''
          (after! dap-mode
            (dap-register-debug-template "Rust::GDB Run Configuration"
                                         (list :type "gdb"
                                               :request "launch"
                                               :name "GDB::Run"
                                               :gdbpath "rust-gdb"
                                               :target nil
                                               :cwd nil)))
        '';
      };
    };
  };
}
