#!/bin/bash

get_headset_battery() {
  local output
  output=$(headsetcontrol -b 2>/dev/null)

  local status
  status=$(echo "$output" | grep 'Status:' | awk '{print $2}')

  local percent
  percent=$(echo "$output" | grep 'Level:' | grep -oP '\d+(?=%)')

  if [ "$status" = "BATTERY_AVAILABLE" ] && [ -n "$percent" ]; then
    echo "{\"percent\": ${percent}, \"available\": true}"
  else
    echo '{"percent": -1, "available": false}'
  fi
}

get_headset_battery

while true; do
  sleep 30
  get_headset_battery
done
