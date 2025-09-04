#!/bin/bash
# /* ---- 💫 Ollama AI Dropdown Panel for Hyprland (Left Slide) 💫 ---- */ ##
DEBUG=false
AI_WS="special:ai"
ADDR_FILE="/tmp/ollama_ai_addr"

# Panel size and position (percentages)
WIDTH_PERCENT=40   # panel width
HEIGHT_PERCENT=96 # full height
X_PERCENT=0        # left edge
Y_PERCENT=3        # top edge

# Animation settings
SLIDE_STEPS=5
SLIDE_DELAY=0.03  # seconds between steps

# Chromium command for Ollama AI WebUI
CHROMIUM_CMD="chromium --app=http://localhost:8080 \
  --enable-features=TransparentVisuals \
  --force-dark-mode \
  --disable-features=GCM \
  --no-first-run"

# Parse debug flag
if [ "$1" = "-d" ]; then
    DEBUG=true
fi

debug_echo() { [ "$DEBUG" = true ] && echo "$@"; }

# Functions to calculate size and position
get_monitor_info() {
    hyprctl monitors -j | jq -r '.[0] | "\(.x) \(.y) \(.width) \(.height)"'
}

calculate_panel_position() {
    local mon_info=$(get_monitor_info)
    local mon_x=$(echo $mon_info | cut -d' ' -f1)
    local mon_y=$(echo $mon_info | cut -d' ' -f2)
    local mon_width=$(echo $mon_info | cut -d' ' -f3)
    local mon_height=$(echo $mon_info | cut -d' ' -f4)

    local width=$((mon_width * WIDTH_PERCENT / 100))
    local height=$((mon_height * HEIGHT_PERCENT / 100))
    local x=$((mon_x + (mon_width * X_PERCENT / 100)))
    local y=$((mon_y + (mon_height * Y_PERCENT / 100)))

    echo "$x $y $width $height"
}

# Animation functions (horizontal)
animate_slide_in() {
    local addr=$1 target_x=$2 target_y=$3 width=$4 height=$5
    local start_x=$((target_x - width - 50))
    local step=$(((target_x - start_x) / SLIDE_STEPS))

    hyprctl dispatch movewindowpixel "exact $start_x $target_y,address:$addr" >/dev/null 2>&1
    sleep 0.05
    for i in $(seq 1 $SLIDE_STEPS); do
        local x_pos=$((start_x + step * i))
        hyprctl dispatch movewindowpixel "exact $x_pos $target_y,address:$addr" >/dev/null 2>&1
        sleep $SLIDE_DELAY
    done
    hyprctl dispatch movewindowpixel "exact $target_x $target_y,address:$addr" >/dev/null 2>&1
}

animate_slide_out() {
    local addr=$1 start_x=$2 start_y=$3 width=$4 height=$5
    local end_x=$((start_x - width - 50))
    local step=$(((start_x - end_x) / SLIDE_STEPS))
    for i in $(seq 1 $SLIDE_STEPS); do
        local x_pos=$((start_x - step * i))
        hyprctl dispatch movewindowpixel "exact $x_pos $start_y,address:$addr" >/dev/null 2>&1
        sleep $SLIDE_DELAY
    done
}

# Window utilities
get_panel_address() { [ -f "$ADDR_FILE" ] && cat "$ADDR_FILE"; }
panel_exists() { local addr=$(get_panel_address); [ -n "$addr" ] && hyprctl clients -j | jq -e --arg ADDR "$addr" 'any(.[]; .address == $ADDR)' >/dev/null 2>&1; }
panel_in_special() { local addr=$(get_panel_address); [ -n "$addr" ] && hyprctl clients -j | jq -e --arg ADDR "$addr" 'any(.[]; .address == $ADDR and .workspace.name == "'"$AI_WS"'")' >/dev/null 2>&1; }

# Spawn panel
spawn_panel() {
    debug_echo "Spawning Ollama AI panel..."
    local pos_info=$(calculate_panel_position)
    local tx=$(echo $pos_info | cut -d' ' -f1)
    local ty=$(echo $pos_info | cut -d' ' -f2)
    local tw=$(echo $pos_info | cut -d' ' -f3)
    local th=$(echo $pos_info | cut -d' ' -f4)

    hyprctl dispatch exec "[float; size $tw $th; workspace $AI_WS silent] $CHROMIUM_CMD"

    sleep 0.2
    # Get latest window
    local addr=$(hyprctl clients -j | jq -r 'sort_by(.focusHistoryID) | .[-1] | .address')
    echo "$addr" > "$ADDR_FILE"
    debug_echo "Panel address: $addr"

    hyprctl dispatch movetoworkspacesilent "$(hyprctl activeworkspace -j | jq -r '.id'),address:$addr"
    hyprctl dispatch pin "address:$addr"
    hyprctl dispatch opacity 0.55 "address:$addr"q
    hyprctl dispatch blur "address:$addr"

    animate_slide_in "$addr" "$tx" "$ty" "$tw" "$th"
}

# Main toggle logic
CURRENT_WS=$(hyprctl activeworkspace -j | jq -r '.id')

if panel_exists; then
    PANEL_ADDR=$(get_panel_address)
    if panel_in_special; then
        debug_echo "Bringing AI panel to current workspace..."
        pos_info=$(calculate_panel_position)
        tx=$(echo $pos_info | cut -d' ' -f1)
        ty=$(echo $pos_info | cut -d' ' -f2)
        tw=$(echo $pos_info | cut -d' ' -f3)
        th=$(echo $pos_info | cut -d' ' -f4)

        hyprctl dispatch movetoworkspacesilent "$CURRENT_WS,address:$PANEL_ADDR"
        hyprctl dispatch pin "address:$PANEL_ADDR"
        hyprctl dispatch resizewindowpixel "exact $tw $th,address:$PANEL_ADDR"
        animate_slide_in "$PANEL_ADDR" "$tx" "$ty" "$tw" "$th"
        hyprctl dispatch focuswindow "address:$PANEL_ADDR"
    else
        debug_echo "Hiding AI panel to special workspace..."
        geometry=$(hyprctl clients -j | jq -r --arg ADDR "$PANEL_ADDR" '.[] | select(.address==$ADDR) | "\(.at[0]) \(.at[1]) \(.size[0]) \(.size[1])"')
        if [ -n "$geometry" ]; then
            curr_x=$(echo $geometry | cut -d' ' -f1)
            curr_y=$(echo $geometry | cut -d' ' -f2)
            curr_w=$(echo $geometry | cut -d' ' -f3)
            curr_h=$(echo $geometry | cut -d' ' -f4)
            animate_slide_out "$PANEL_ADDR" "$curr_x" "$curr_y" "$curr_w" "$curr_h"
            hyprctl dispatch pin "address:$PANEL_ADDR"
            hyprctl dispatch movetoworkspacesilent "$AI_WS,address:$PANEL_ADDR"
        fi
    fi
else
    spawn_panel
fi
