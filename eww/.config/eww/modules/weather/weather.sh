#!/bin/bash

set -u

location="97214"

get_weather() {
  local endpoint="https://wttr.in/${location}?format=j1"

  curl --silent --show-error --max-time 10 "$endpoint" 2>/dev/null | jq -c '{
    temp: ((.current_condition[0].temp_F // .current_condition[0].temp_C // "--") | tostring) + "°",
    humidity: ((.current_condition[0].humidity // "--") | tostring) + "%"
  }' 2>/dev/null || echo '{"temp":"--","humidity":"--%"}'
}

get_weather

while true; do
  sleep 900
  get_weather
done
