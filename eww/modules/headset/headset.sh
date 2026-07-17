#!/bin/bash

get_headset_battery() {
  local output
  output=$(headsetcontrol -b 2>/dev/null)

  local status
  status=$(echo "$output" | grep 'Status:' | awk '{print $2}')

  local percent
  percent=$(echo "$output" | grep 'Level:' | grep -oP '\d+(?=%)')

  local charging=false
  [ "$status" = "BATTERY_CHARGING" ] && charging=true

  if { [ "$status" = "BATTERY_AVAILABLE" ] || [ "$charging" = true ]; } && [ -n "$percent" ]; then
    echo "{\"percent\": ${percent}, \"available\": true, \"charging\": ${charging}}"
  else
    echo '{"percent": -1, "available": false, "charging": false}'
  fi
}

get_headset_battery

while true; do
  sleep 10
  get_headset_battery
done
