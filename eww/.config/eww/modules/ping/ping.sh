#!/bin/bash
# Use fping and parse its output for latency or timeout
fping -l $1 | while read -r line; do
    # If the line contains 'timed out', print Fail
    if echo "$line" | grep -q 'timed out'; then
        echo "---"
    else
        # Extract the ms value before 'ms' and print it
        latency=$(echo "$line" | grep -o '[0-9.]* ms' | head -n1 | awk '{print $1}')
        if [ -n "$latency" ]; then
            echo "$latency"
        fi
    fi
done