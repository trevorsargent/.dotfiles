#!/bin/bash

get_gpu() {
  nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total \
    --format=csv,noheader,nounits 2>/dev/null \
    | awk -F', ' '{
        used = $2; total = $3;
        perc = (total > 0) ? (used / total * 100) : 0;
        printf "{\"util\":%d,\"mem_used_mib\":%d,\"mem_total_mib\":%d,\"mem_perc\":%.1f}\n", $1, used, total, perc
      }'
}

get_gpu

while true; do
  sleep 2
  get_gpu
done
