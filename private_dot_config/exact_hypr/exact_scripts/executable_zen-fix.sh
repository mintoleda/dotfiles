#!/bin/bash

# Launch Zen Browser safely
# This avoids the previous behavior of killing the process which caused crashes

ZEN_BIN="/opt/zen-browser-bin/zen-bin"

if pgrep -f "zen-bin" > /dev/null; then
    # Zen is already running, open a new window or focus
    exec "$ZEN_BIN" "$@"
else
    # Zen is not running, start it
    exec "$ZEN_BIN" "$@"
fi
