#!/bin/bash

SVG_DIR="/tmp/eww-workspace-svgs"
rm -rf "$SVG_DIR"
mkdir -p "$SVG_DIR"

TIMESTAMP=$(date +%s%N)

get_workspaces() {
  workspaces=$(hyprctl workspaces -j)
  clients=$(hyprctl clients -j)
  monitors=$(hyprctl monitors -j)
  ts=$(date +%s%N)

  result=$(echo "$workspaces" | jq -c --argjson clients "$clients" --argjson monitors "$monitors" --arg ts "$ts" '
    sort_by(.id) | map(. as $ws |
      ($monitors | map(select(.name == $ws.monitor)) | .[0]) as $mon |
      ($clients | map(select(.workspace.id == $ws.id)) | map({
        x: (((.at[0] - ($mon.x // 0)) / ($mon.width // 3840) * 100) | round),
        y: (((.at[1] - ($mon.y // 0)) / ($mon.height // 2160) * 100) | round),
        w: ((.size[0] / ($mon.width // 3840) * 100) | round),
        h: ((.size[1] / ($mon.height // 2160) * 100) | round)
      })) as $windows |
      {
        id: .id,
        name: .name,
        monitor: .monitor,
        windows: $windows,
        ts: $ts,
        svg: (
          "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 100 56\" preserveAspectRatio=\"none\">" +
          ($windows | map(
            "<rect x=\"\(.x + 1)\" y=\"\(.y * 56 / 100 + 1)\" width=\"\(.w - 2)\" height=\"\(.h * 56 / 100 - 2)\" rx=\"2\" fill=\"rgba(255,255,255,0.12)\"/>"
          ) | join("")) +
          "</svg>"
        )
      }
    )
  ')

  # Write SVG files with timestamp
  echo "$result" | jq -r '.[] | "\(.id)\t\(.ts)\t\(.svg)"' | while IFS=$'\t' read -r id ts svg; do
    echo "$svg" > "$SVG_DIR/ws-$id-$ts.svg"
  done

  # Output JSON with svg_path
  echo "$result" | jq -c 'map(. + {svg_path: "/tmp/eww-workspace-svgs/ws-\(.id)-\(.ts).svg"} | del(.svg) | del(.ts))'
  
  # Clean up old SVGs (keep only latest)
  find "$SVG_DIR" -name "*.svg" -mmin +1 -delete 2>/dev/null
}

get_workspaces

socat -u UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock - | while read -r line; do
  get_workspaces
done
