#!/bin/bash
# Linux-Universe: mutual-surveillance watchdog (part of a 5-node ring)

ID="$1"
TOTAL=5
HB_DIR="/var/lib/linux-universe/watchdog-heartbeats"
STATE_FILE="/var/lib/linux-universe/airgap-state"
mkdir -p "$HB_DIR"

while true; do
    date +%s > "$HB_DIR/wd${ID}"

    if [ -f "$STATE_FILE" ] && [ "$(cat "$STATE_FILE")" = "on" ]; then
        NET_STATE=$(nmcli networking 2>/dev/null)
        if [ "$NET_STATE" != "disabled" ]; then
            logger -t "linux-universe-watchdog" "WD${ID}: detected network re-enabled while Air-Gap=on, re-enforcing"
            nmcli networking off
            rfkill block all
            iptables -P INPUT DROP 2>/dev/null
            iptables -P OUTPUT DROP 2>/dev/null
            iptables -P FORWARD DROP 2>/dev/null
        fi
    fi

    for OTHER in $(seq 1 "$TOTAL"); do
        [ "$OTHER" = "$ID" ] && continue
        HB_FILE="$HB_DIR/wd${OTHER}"
        NOW=$(date +%s)
        if [ -f "$HB_FILE" ]; then
            LAST=$(cat "$HB_FILE" 2>/dev/null || echo 0)
            if [ $((NOW - LAST)) -gt 30 ]; then
                logger -t "linux-universe-watchdog" "WD${ID}: watchdog ${OTHER} heartbeat stale, restarting"
                systemctl unmask "linux-universe-watchdog@${OTHER}.service" 2>/dev/null
                systemctl restart "linux-universe-watchdog@${OTHER}.service" 2>/dev/null
            fi
        else
            logger -t "linux-universe-watchdog" "WD${ID}: watchdog ${OTHER} has no heartbeat, restarting"
            systemctl unmask "linux-universe-watchdog@${OTHER}.service" 2>/dev/null
            systemctl restart "linux-universe-watchdog@${OTHER}.service" 2>/dev/null
        fi
    done

    sleep $(( (RANDOM % 10) + 5 ))
done
