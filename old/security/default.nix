{
  dotfiles.home-manager = {pkgs, ...}: {
    home.packages = with pkgs; [
      cotp
      trufflehog

      # Hacking
      armitage
      metasploit
      flawz
    ];
  };
}
