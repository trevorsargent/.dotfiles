# Pi bundles Node under a versioned, platform-specific directory. Select the
# most recently installed bundle without hardcoding a version or architecture.
_pi_bins=( $HOME/.local/share/pi-node/node-*/bin(N/Om[1]) )
(( ${#_pi_bins} )) && path=( $_pi_bins $path )
unset _pi_bins
