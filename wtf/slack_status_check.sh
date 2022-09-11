#!/bin/sh

curl -s https://status.slack.com/api/v2.0.0/current | \
  jq -r '"Status: " + (if (.status == "active") then "Active Incident" else "Ok" end),"Last Updated: " + .date_updated,if (.active_incidents[] | length) > 0 then "Active Incidents\n" + .active_incidents[] .title else "" end'