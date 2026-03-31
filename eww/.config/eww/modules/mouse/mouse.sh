#!/bin/bash

get_mouse_battery() {
  local output
  output=$(solaar show 'MX Master 3S' 2>/dev/null)

  local battery_line
  battery_line=$(echo "$output" | grep 'Battery:' | tail -1)

  local percent
  percent=$(echo "$battery_line" | grep -oP '\d+(?=%)')

  local charging="false"
  if echo "$battery_line" | grep -qi 'recharging'; then
    charging="true"
  fi

  if [ -n "$percent" ]; then
    echo "{\"percent\": ${percent}, \"charging\": ${charging}}"
  else
    echo '{"percent": -1, "charging": false}'
  fi
}

get_mouse_battery

while true; do
  sleep 30
  get_mouse_battery
done
