#!/bin/bash
# Ollama + Open-WebUI controller script (detects running Ollama by process name)
# Usage: ./ai_control.sh start|stop

OPEN_WEBUI_CONTAINER="open-webui-cpu"
OLLAMA_LOG="/tmp/ollama_serve.log"
OLLAMA_PID_FILE="/tmp/ollama_serve.pid"

log() { echo "[INFO] $1"; }

# Detect Ollama PID by process name
get_ollama_pid() {
    pgrep -f "ollama serve"
}

start_services() {
    # Start Ollama Serve if not running
    pid=$(get_ollama_pid)
    if [ -n "$pid" ]; then
        log "Ollama Serve is already running (PID $pid)."
    else
        log "Starting Ollama Serve..."
        nohup ollama serve > "$OLLAMA_LOG" 2>&1 &
        pid=$!
        echo $pid > "$OLLAMA_PID_FILE"
        sleep 2
        log "Ollama Serve started (PID $pid)."
    fi

    # Start Open-WebUI Docker container if not running
    if docker ps --format '{{.Names}}' | grep -q "^${OPEN_WEBUI_CONTAINER}\$"; then
        log "Open-WebUI-CPU container is already running."
    else
        if docker ps -a --format '{{.Names}}' | grep -q "^${OPEN_WEBUI_CONTAINER}\$"; then
            log "Starting existing Open-WebUI-CPU container..."
            docker start "$OPEN_WEBUI_CONTAINER" >/dev/null
        else
            log "Container $OPEN_WEBUI_CONTAINER not found!"
            return 1
        fi
    fi
}

stop_services() {
    # Stop Ollama Serve
    pid=$(get_ollama_pid)
    if [ -n "$pid" ]; then
        log "Stopping Ollama Serve (PID $pid)..."
        kill $pid
        [ -f "$OLLAMA_PID_FILE" ] && rm -f "$OLLAMA_PID_FILE"
    else
        log "Ollama Serve is not running."
    fi

    # Stop Open-WebUI Docker container
    if docker ps --format '{{.Names}}' | grep -q "^${OPEN_WEBUI_CONTAINER}\$"; then
        log "Stopping Open-WebUI-CPU container..."
        docker stop "$OPEN_WEBUI_CONTAINER" >/dev/null
    else
        log "Open-WebUI-CPU container is not running."
    fi
}

# --- Main ---
case "$1" in
    start) start_services ;;
    stop) stop_services ;;
    *) echo "Usage: $0 start|stop"; exit 1 ;;
esac
