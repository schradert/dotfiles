def edit(incoming; appid):
  incoming
  | .shortcut
  | del(.appname, .StartDir) // {}
  | to_entries
  | map("\(.key)=\(.value)" | @sh)
  | join(" ")
  | "\($nostatoo) edit-non-steam-game \(appid) \(.)"
  ;

def add_assets(incoming; appid):
  incoming
  | .assets // {}
  | to_entries
  # add-asset fails with "initialize: permission denied @ rb_sysopen" if it already exists, so we remove first
  | map(["\($nostatoo) remove-asset \(appid) \(.key)", "\($nostatoo) add-asset \(appid) \(.key) \(.value)"] | join("\n"))
  | join("\n")
  ;

.
  | ($previous_dump | .shortcuts | map(select(.appname | endswith(" (Nostatoo)")))) as $previous
  # FULL OUTER JOIN is not supported, so we do a left outer and right outer as "incoming" and "previous" respectively
  # NOTE https://github.com/jqlang/jq/issues/1090
  # NOTE Joins must be surrounded with [] because they generate streams that must be collected to avoid --slurp
  | ([JOIN(INDEX($previous[]; .appname); $incoming[]; .shortcut.appname)]) as $incoming_join
  | ([JOIN(INDEX($incoming[]; .shortcut.appname); $previous[]; .appname)]) as $previous_join
  | {
      add: $incoming_join | map(
        select(.[1] == null)
        | .[0]
        | [
            (.shortcut | "appid=$(\($nostatoo) add-non-steam-game \((.appname + " (Nostatoo)") | @sh) \(.exe | @sh) \(.StartDir | @sh))"),
            edit(.; "$appid"),
            add_assets(.; "$appid")
          ]
        | join("\n")
      ),
      edit: $incoming_join | map(
        select(.[1] != null)
        # Editing requires "previous" appid to assign "incoming" data
        | (.[1].appid) as $appid
        | .[0]
        | [
            edit(.; $appid),
            add_assets(.; $appid)
          ]
        | join("\n")
      ),
      remove: $previous_join | map(
        select(.[1] == null)
        # Removing just requires "previous" appid
        | "\($nostatoo) remove-non-steam-game \(.[0].appid)"
      ),
      # TODO support noop to avoid running pointless edit/add-asset commands
    }
  | to_entries
  | map(.value)
  | flatten
  | join("\n")
