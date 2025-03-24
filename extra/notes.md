# Dotfiles

## Order

1. cilium (crds have to go first in bootstrap)
2. prometheus
3. coredns
4. kubelet-csr-approver
5. spegel
6. cert-manager (nginx must wait)
7. external-dns
8. cloudflared
9. nginx-internal
10. nginx-external
11. snapshot-controller
12. volsync
13. reloader
14. descheduler
15. node-feature-discovery
16. k8tz
17. openebs
18. grafana
19. rook-ceph + rook-ceph-cluster
20. loki
21. external-secrets
22. postgres
23. postgres-ui
24. keycloak
25. gatus

## TODOs

### Devices

[ ] Nix build machines (distributed)!
[ ] how to keep ssh agent alive?!
[ ] longer timeouts for screen lock
[ ] decky-loader plugins
[ ] window management in hyprland
[ ] full hyprland config
[ ] integrate nvd
[ ] fix auto-zellij
[ ] guarantee spicetify works
[ ] YubiKey login/lock
[ ] doom as application
[ ] merge changes into canivete
[ ] create open PRs on jovian, nixpkgs, home-manager, steam-rom-manager, nostatoo, etc.
[ ] [WayVNC](https://github.com/any1/wayvnc)

[ ] VPN
[ ] separate nostatoo install from final executable
[ ] allow package installation after initial game launch in steam
[ ] DECIDE nostatoo vs steam-rom-manager for manual programs
[ ] steam controller VDF configuration
[ ] Steam Deck memory card!
[ ] Steam Deck dock memory!
[ ] Steam Deck remote play games on desktop (how to work with autosleep/wake?)
[ ] mobile-nixos on S21 FE
[ ] asahi-nixos on one of the old Macs
[ ] make a nix store binary bucket on backblazes
[ ] add images for manual programs
[ ] fix monitor resolution on axolotl
[ ] allow ME to rebuild without sudo
[ ] TTY device (`lemurs` or `ly` or `tuigreet` would be fun!)
[ ] run BOINC agent in cluster
[ ] themes for browser
[ ] game servers, maybe with some ideas taken from [pelican](https://github.com/pelican-dev/panel)

[ ] [rosepine](https://github.com/rose-pine/userstyles) (should I have a general theme for this?)

[ ] switch systemd-boot to grub and add theme with ventoy too

- [Minecraft](https://github.com/Lxtharia/double-minegrub-menu)

[ ] use kando for controller and touch screen menus

- but can it be used with hotkeys?

[ ] browser startpage

- [startup-page](https://github.com/timothypholmes/startup-page)
- [NightTab](https://github.com/zombieFox/nightTab)

[ ] full desktop in game mode with steam input!

- [Game Mode](https://www.reddit.com/r/SteamDeck/comments/10toj3c/linux_handheld_desktop_gaming_pc_feat/)
- [Comment](https://www.reddit.com/r/unixporn/comments/10tt6qi/comment/j79krny/)

[ ] [portable monitor rig](https://www.youtube.com/watch?v=aUKpY0o5tMo)
[ ] emacs-eaf with eaf-markmap
[ ] recreate [brows](https://github.com/rubysolo/brows) with gh + fzf
[ ] is [noi](https://github.com/lencx/Noi) better than alternatives?
[ ] set up [proxmox](https://github.com/SaumonNet/proxmox-nixos)
[ ] ensure qemu support for emulating other architectures
[ ] create [mdBook](https://github.com/rust-lang/mdBook) site (graphviz, asciidoc, typst, latex, org-mode, mdx, etc.!)
[ ] replace coreutils + findutils + diffutils with uutils-coreutils (faster and safer rust implementations)
[ ] use slidev to host slide applications ([patat](https://github.com/jaspervdj/patat) for TUI :))
[ ] is it useful to have something like [portainer](https://github.com/portainer/portainer)
[ ] how to integrate [Real Time Voice Cloning](https://github.com/CorentinJ/Real-Time-Voice-Cloning) into pipelines
[ ] [GPT Engineer](https://github.com/AntonOsika/gpt-engineer)
[ ] [OpenPilot](https://github.com/commaai/openpilot)
[ ] look into OpenTelemetry with [SigNoz](https://github.com/SigNoz/signoz) and [otel-tui](https://github.com/ymtdzzz/otel-tui)
[ ] [Faro](https://github.com/grafana/faro-web-sdk) is in the Grafana ecosystem!
[ ] [GlitchTip](https://gitlab.com/glitchtip) vs. [Sentry](https://github.com/getsentry/sentry)
[ ] [Deep Fake Live Cam](https://github.com/hacksider/Deep-Live-Cam)
[ ] [Open Assistant](https://github.com/LAION-AI/Open-Assistant)
[ ] [FastChat](https://github.com/lm-sys/FastChat)
[ ] clean up home with [xdg-ninja](https://github.com/b3nj5m1n/xdg-ninja)
[ ] [Zen Browser](https://github.com/0xc000022070/zen-browser-flake) with [LibreWolf privacy](https://www.reddit.com/r/LibreWolf/comments/1fw9aq4/zen_browser_ui_on_librewolf/) or [Betterfox](https://github.com/yokoffing/Betterfox) but with [reservations](https://www.reddit.com/r/LibreWolf/comments/1ezumu7/comment/ljnjx2b/?share_id=1j3JDYiGHQxyPg2mcE3vj) and [mods](https://zen-browser.app/mods/) in twilight mode!
[ ] [audiobookshelf](https://github.com/advplyr/audiobookshelf) any good?
[ ] [bonfire](https://github.com/bonfire-networks/bonfire-app) any good?
[ ] [Bridgy Fed](https://github.com/snarfed/bridgy-fed) for connecting decentralized applications
[ ] [Bookwyrm](https://github.com/bookwyrm-social/bookwyrm) with [hosting](https://docs.joinbookwyrm.com/)
[ ] [Deep Flow](https://github.com/deepflowio/deepflow) is it useful?
[ ] [lichess](https://github.com/lichess-org/lila)
[ ] [Monica/Chandler](https://github.com/monicahq/monica)
[ ] [koel](https://github.com/koel/koel?tab=readme-ov-file) with [mobile](https://github.com/koel/player)
[ ] [kong](https://github.com/Kong/kong) do I need something like this?
[ ] [readme stats](https://github.com/anuraghazra/github-readme-stats) on all repos
[ ] [kmonad](https://github.com/kmonad/kmonad) is this even more useful for me?
[ ] [nix-gaming](https://github.com/fufexan/nix-gaming) will this help at all?
[ ] [motioneye](https://github.com/motioneye-project/motioneye) useful for home security?
[ ] [changedetector](https://github.com/dgtlmoon/changedetection.io) can I use this to send myself notifications when things upstream change?
[ ] [SMARTd](https://github.com/AnalogJ/scrutiny) useful?
[ ] [ntopng](https://github.com/ntop/ntopng) useful?
[ ] [NorthstarProton](https://github.com/R2NorthstarTools/NorthstarProton) to run Titanfall 2
[ ] would nvtop be valuable?
[ ] what even tstreaming platform should I be using? kafka? can I use [kaskade](https://github.com/sauljabin/kaskade) otherwise?
[ ] should I try clickhouse or druid? use TUI :)
[ ] facter vs nixos-generate-config vs nixos-hardware

### Firefox extensions

[Frame](https://addons.mozilla.org/en-US/firefox/addon/frame-extension/)

uBlock

### Services

[ ] Why doesn't cilium agent run on axolotl?
[ ] persistence
[ ] annotations
[ ] resources
[ ] securityContext
[ ] separate default.yaml and kubernetes.yaml SOPS (track static vs dynamic)
[ ] bootstrap images on k3s agents for traefik and forgejo
[ ] VLANs
[ ] instructions for setting up new nodes
[ ] Create a repair command for nix after macOS update per [this working solution](https://discourse.nixos.org/t/nix-commands-missing-after-macos-12-1-version-upgrade/16679/5)
[ ] [rke2](https://search.nixos.org/options?channel=unstable&from=0&size=50&sort=alpha_asc&type=packages&query=rke2)
[ ] network bonding
[ ] Pushover/notification system
[ ] add tristanschrader.com redirect and email obfuscation deactivation to opentofu
[ ] add keycloak client creation to opentofu
[ ] add firefly multi-user configuration to terraform
[ ] remove extra fields from external-secrets
[ ] fix rook-ceph OSDs to be correctly distributed
[ ] fix bluetooth delay for Between Micro and Steam Deck + axolotl [Wiki](https://nixos.wiki/wiki/Bluetooth)
[ ] [waypipe](https://gitlab.freedesktop.org/mstoeckl/waypipe) do I need this to run `ssh -X`
[ ] notification OSDs: [avizo](https://github.com/heyjuvi/avizo) [SwayOSD](https://github.com/ErikReider/SwayOSD)
[ ] mobile linux keyboard:
[ ] run [carbonyl](https://github.com/fathyb/carbonyl) with steam-run and github binary
[ ] run [tango](https://github.com/yume-chan/ya-webadb) on cluster for ADB
[ ] run [shizuku](https://github.com/RikkaApps/Shizuku) on android devices
[ ] declarative router with [dewclaw](https://github.com/MakiseKurisu/dewclaw)

- probably some inspiration [here](https://github.com/Mic92/dotfiles/tree/main/openwrt) too

[ ] capture browser extensions in nix
[ ] [SXMO](https://sxmo.org/)
[ ] [squeekboard](https://gitlab.gnome.org/World/Phosh/squeekboard)
[ ] [swipeGuess](https://git.sr.ht/~earboxer/swipeGuess)
[ ] [clickclack](https://git.sr.ht/~proycon/clickclack)
[ ] [wvkbd](https://github.com/jjsullivan5196/wvkbd)
[ ] is [midarr](https://github.com/midarrlabs/midarr-server) any good or useful?
[ ] look through [awesome-cli-apps](https://github.com/agarrharr/awesome-cli-apps) for good stuff and [terminals-are-sexy](https://github.com/k4m4/terminals-are-sexy)
[ ] [pidgin](pidgin.im)

### Kubernetes

[ ] [Is `kctrl` useful?](https://carvel.dev/blog/kctrl-release-blog/)
[ ] `FluxCD` vs `kapp`

## Bugs

[ ] Why does nix.mkIf create infinite recursion?
[ ] Why does moduleWithSystem lib.mkIf create infinite recursion?
[ ] Why does mkDomainOption give "deprecationMessage missing"
[ ] fix [chiaki](https://github.com/streetpea/chiaki-ng/issues/448)
[ ] [Sui](https://github.com/RikkaApps/Sui) on rooted Android devices with Magisk

## Tips

Apply these annotations to services that need the oauth2-proxy

```nix
annotations."nginx.ingress.kubernetes.io/auth-url" = "https://oauth2-proxy.${domain}/oauth2/auth?allowed_groups=/family";
annotations."nginx.ingress.kubernetes.io/auth-signin" = "https://oauth2-proxy.${domain}/oauth2/start?rd=$scheme://$host$request_uri";
```

## Wallpapers

1. [reality-explorer-theme](https://github.com/v1ewport/reality-explorer-theme/tree/main/Wallpapers)
2. [another](https://github.com/SherLock707/hyprland_dot_yadm/blob/main/Pictures/wallpapers/jinx_ekko_sitting3.png)
