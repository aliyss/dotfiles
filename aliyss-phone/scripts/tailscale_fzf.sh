#!/data/data/com.termux/files/usr/bin/fish

# Check if fzf is installed
set HAS_FZF 0
if command -v fzf >/dev/null 2>&1
    set HAS_FZF 1
end

# 1. Daemon Check & Action Selection
if tailscale-cli status >/dev/null 2>&1
    echo "[!] Tailscale daemon is currently running."
    
    set ACTION ""
    if test $HAS_FZF -eq 1
        # Primary: Use fzf for menu choices
        set MENU_OPTIONS "Continue to SSH\nStop Tailscale\nExit"
        set CHOICE (echo -e $MENU_OPTIONS | fzf --header="Tailscale is active. Select action:")
        
        switch "$CHOICE"
            case "Stop Tailscale"
                set ACTION "stop"
            case "Exit"
                set ACTION "exit"
            case "Continue to SSH"
                set ACTION "continue"
            case "*"
                # Cancelled fzf (e.g., pressed Esc)
                echo "Cancelled."
                exit 0
        end
    else
        # Fallback: Plain terminal read prompt
        read -P "Choose action - [c]ontinue to SSH, [s]top server, [e]xit [C/s/e]: " choice
        switch (string lower -- "$choice")
            case s stop
                set ACTION "stop"
            case e exit
                set ACTION "exit"
            case '*'
                set ACTION "continue"
        end
    end

    # Process selected action
    switch "$ACTION"
        case stop
            echo "[*] Stopping tailscaled..."
            pkill -f tailscaled 2>/dev/null
            echo "[+] Tailscale stopped."
            exit 0
        case exit
            echo "Exiting."
            exit 0
        case continue
            echo "[+] Continuing to SSH selection..."
    end
else
    echo "[+] Tailscale is off. Starting tailscaled..."
    
    nohup tailscaled-start >/dev/null 2>&1 &
    disown
    sleep 2
    
    if not tailscale-cli status >/dev/null 2>&1
        echo "[-] Failed to connect to local tailscaled daemon."
        exit 1
    end
    echo "[+] Tailscale started successfully."
end

# 2. Verify Backend Connection State
set TS_STATE (tailscale-cli status --json 2>/dev/null | jq -r '.BackendState // "Stopped"')

if test "$TS_STATE" != "Running"
    echo "[-] Tailscale backend state is: $TS_STATE"
    echo "[*] Run 'tailscale-cli up' to connect."
    exit 1
end

# 3. Query Devices
set NODES (tailscale-cli status --json 2>/dev/null | jq -r '
    .Peer[]? 
    | "\(.HostName) [\(if .Online then "online" else "offline" end)]"
')

if test -z "$NODES"
    echo "[!] No Tailscale peers found on this account."
    exit 0
end

# 4. Device Selection & SSH
set SELECTED_NODE ""

if test $HAS_FZF -eq 1
    # Primary: fzf selection
    set RAW_SELECTION (string split \n -- $NODES | fzf --header="Select Tailscale SSH Destination:")
    set SELECTED_NODE (string split " " -- $RAW_SELECTION)[1]
else
    # Fallback: Sequential list and read prompt
    echo "Available nodes:"
    set NODE_ARRAY (string split \n -- $NODES)
    for i in (seq (count $NODE_ARRAY))
        echo "  $i) $NODE_ARRAY[$i]"
    end
    read -P "Select node number: " index
    if test -n "$index"; and string match -qr '^[0-9]+$' -- "$index"
        set RAW_SELECTION $NODE_ARRAY[$index]
        set SELECTED_NODE (string split " " -- $RAW_SELECTION)[1]
    end
end

if test -n "$SELECTED_NODE"
    echo "Connecting to $SELECTED_NODE via tailscale ssh..."
    tailscale-cli ssh "$SELECTED_NODE"
else
    echo "No node selected."
end

