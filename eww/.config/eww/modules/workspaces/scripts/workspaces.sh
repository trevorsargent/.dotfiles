#!/bin/bash

hyprctl workspaces -j | jq -c 'sort_by(.id)'