#!/bin/bash

get_sensors() {
  sensors -j 2>/dev/null | jq -c '{
    "cpu_temp": (."k10temp-pci-00c3".Tctl.temp1_input // 0 | round),
    "gpu_temp": (."amdgpu-pci-1000".edge.temp1_input // 0 | round),
    "case_fan": (."nct6687-isa-0a20".fan2.fan2_input // 0 | round)
  }'
}

get_sensors

while true; do
  sleep 2
  get_sensors
done
