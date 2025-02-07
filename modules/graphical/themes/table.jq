.
  | (["Name"] + (.[keys_unsorted[0]] | keys | map((.[0:1] | ascii_upcase) + .[1:]))) as $header
  | (to_entries | map([.key] + (.value | [.[] | .name]))) as $rows
  | [$header, $rows[]]
  | map(@csv)[]
