#!/bin/bash
# Window switcher: pick an open window in wofi (dmenu mode) and focus it.
# Labels and addresses come from one hyprctl snapshot so they can't drift apart.
json=$(hyprctl clients -j)
mapfile -t addrs < <(jq -r '.[] | select(.mapped) | .address' <<<"$json")
mapfile -t labels < <(jq -r '.[] | select(.mapped) | "[\(.workspace.name)] \(.class): \(.title)"' <<<"$json")

choice=$(printf '%s\n' "${labels[@]}" | GTK_THEME=Default wofi --show dmenu --prompt window)
[ -z "$choice" ] && exit 0

for i in "${!labels[@]}"; do
    if [ "${labels[$i]}" = "$choice" ]; then
        hyprctl dispatch focuswindow "address:${addrs[$i]}"
        exit 0
    fi
done
