#!/usr/bin/env bash

hyprctl monitors -j | jq -c 'map({key: .name|tostring, value:.activeWorkspace.id}) | from_entries'
socat -u UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock - | while read -r line; do
  hyprctl monitors -j | jq -c 'map({key: .name|tostring, value:.activeWorkspace.id}) | from_entries'
done