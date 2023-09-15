{
      getAttrs = l: a: map (s: s.${a}) l;
      computers = [
        { hostname = "Nadjas-Air"; username = "tristanschrader"; home_d = "/Users"; }
        { hostname = "morgenmuffel"; username = "tristanschrader"; home_d = "/Users"; }
        { hostname = "Daniels-iPhone"; username = "tristanschrader"; home_d = "/Users"; }
      ];
      computersIndexed = listToAttrs (map (c: { name = c.hostname; value = c; }) computers);
      hostnames = attrNames computersIndexed;
      usernames = getAttrs computers "username";
      getHostnameUser = hn: computersIndexed.${hn}.username;
      getHostnameUserDirectory = hn: "${computersIndexed.${hn}.home_d}/${getHostnameUser hn}";
      getHostSessionFolder = hn: s: "${getHostnameUserDirectory hn}/Code/${s.path}";
      getPaneName = s: wn: pi: "${s.name}:${wn}.${toString pi}";
      readHostDir = hn: s: readDir (/. + (getHostSessionFolder hn s));
      defaultWindow = "explore";
      cmds.list-windows = hn: s: attrNames (filterAttrs (_: v: v == "directory") (readHostDir hn s));
      cmds.create-session = s: "tmux new-session -d -s ${s.name} -n ${defaultWindow} -c ${s.cwd}";
      cmds.has-session = s: "tmux list-sessions | grep -q ${s.name}";
      cmds.create-window = s: wn: "tmux new-window -d -n ${wn} -t ${s.name}: -c ${s.cwd}/${wn}";
      cmds.create-windows = s: concatStringsSep "\n" (map (cmds.create-window s) s.windows);
      cmds.split-pane = s: pi: flags: wn: "tmux split-window -d -t ${getPaneName s wn pi} ${flags}";
      cmds.split-panes = s: pi: flags: concatStringsSep "\n" (map (cmds.split-pane s pi flags) s.windows);
      cmds.rename-tab = s: "rename_wezterm_title ${s.name}";
      cmds.attach-tab = s: "tmux attach-session -t ${s.name}";
      cmds.spawn-session = s: "wezterm cli spawn --cwd ${s.cwd}";
      cmds.run-pane-cmd = s: pi: cmd: wn:
        "tmux send-keys -t ${getPaneName s wn pi} '[[ -d ${s.cwd}/${wn} ]] && cd ${s.cwd}/${wn}; ${cmd}' Enter";
      cmds.run-pane-cmds = s: pi: cmd: concatStringsSep "\n" (map (cmds.run-pane-cmd s pi cmd) s.windows);
      cmds.build-session = s: ''
        ${cmds.has-session s} || {

          # Create session default window
          ${cmds.create-session s}
          ${cmds.run-pane-cmd s 0 "ranger" defaultWindow}

          # Run commands for each project window
          ${cmds.create-windows s}
          ${cmds.split-panes s 0 "-h"}
          ${cmds.split-panes s 1 "-v"}
          ${cmds.run-pane-cmds s 0 "vim"}
          ${cmds.run-pane-cmds s 1 "ranger"}
          ${cmds.run-pane-cmds s 2 "tig"}
        }
        ${cmds.spawn-session s}
        pane_id="$(wezterm cli list | grep ${s.name} | tr -s ' ' | cut -d ' ' -f 4)"
        wezterm cli send-text --no-paste --pane-id $pane_id "${cmds.rename-tab s} && ${cmds.attach-tab s}"
      '';
      cmds.build-sessions = ss: concatStringsSep "\n" (map cmds.build-session ss);
      cmds.run-wezmux = ss: ''
        #!/usr/bin/env bash
        ${cmds.build-sessions ss}
      '';
      bin.write-script = name: text: (pkgs.writeScriptBin name text).overrideAttrs (old: {
        buildCommand = "${old.buildCommand}\n patchShebangs $out";
      });
      sessions = [
        { name = "climax"; path = "Work"; }
        { name = "bunkbed"; path = "Personal/bunkbed"; }
        { name = "vilf"; path = "Personal/vilf"; }
        { name = "dev"; path = "Personal/dev"; }
        { name = "hive"; path = "Personal/electrichive"; }
        { name = "terrace"; path = "Personal/terrace"; }
        { name = "couchers"; path = "Personal/couchers"; }
      ];
      getHostSessions = hn:
        map (s: s // { cwd = getHostSessionFolder hn s; windows = cmds.list-windows hn s; }) sessions;
      getWezmuxCommand = hn: cmds.run-wezmux (getHostSessions hn);

      scripts._wezmux = genAttrs hostnames (hn: bin.write-script "_wezmux_${hn}" (getWezmuxCommand hn));
      scripts.wezmux = bin.write-script "wezmux" ''
        #!/usr/bin/env bash
        ${cmds.get-host}
        nix run .#_wezmux.$host --impure
      '';
}
