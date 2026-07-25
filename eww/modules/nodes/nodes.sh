#!/bin/bash
# Stream cpu/memory stats for a remote node over a single persistent ssh session.
# Emits one JSON line per sample; emits an "down" line whenever the session drops.
host="$1"

down='{"up":false,"cpu":0,"mem":0,"mem_used_mib":0,"mem_total_mib":0}'

while true; do
  ssh -o BatchMode=yes \
      -o ConnectTimeout=5 \
      -o ServerAliveInterval=10 \
      -o ServerAliveCountMax=2 \
      -o StrictHostKeyChecking=accept-new \
      "root@$host" bash -s <<'REMOTE'
prev_total=0
prev_idle=0
first=1
while :; do
  read -r _ user nice system idle iowait irq softirq steal _ < /proc/stat
  total=$((user + nice + system + idle + iowait + irq + softirq + steal))
  idle_all=$((idle + iowait))
  dt=$((total - prev_total))
  di=$((idle_all - prev_idle))
  prev_total=$total
  prev_idle=$idle_all

  cpu=0
  [ "$dt" -gt 0 ] && cpu=$(( (100 * (dt - di) + dt / 2) / dt ))

  mem_total=$(awk '/^MemTotal:/{print $2}' /proc/meminfo)
  mem_avail=$(awk '/^MemAvailable:/{print $2}' /proc/meminfo)
  mem_used=$((mem_total - mem_avail))
  mem=0
  [ "$mem_total" -gt 0 ] && mem=$((mem_used * 100 / mem_total))

  if [ "$first" -eq 1 ]; then
    first=0
  else
    printf '{"up":true,"cpu":%d,"mem":%d,"mem_used_mib":%d,"mem_total_mib":%d}\n' \
      "$cpu" "$mem" "$((mem_used / 1024))" "$((mem_total / 1024))"
  fi
  sleep 2
done
REMOTE
  echo "$down"
  sleep 5
done
