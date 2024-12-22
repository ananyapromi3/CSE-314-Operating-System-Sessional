#!/usr/bin/bash

# Usage: ./receive_email.sh
# Continuously reads and monitors the log file for alerts

LOG_FILE="email.log"
SENDER_ALERT="enemy"


# Ensure the log file exists
if [ ! -f "$LOG_FILE" ]; then
    touch "$LOG_FILE"
    echo "Log file created: $LOG_FILE"
fi
declare -a content
flag=0
# Tail the log file and keep monitoring in real-time
tail -F "$LOG_FILE" | while read -r line; do

    content+=("$line")
    
    # If the line is ---, then the email content has ended
    if [[ "$line" == "---" ]]; then
        if (( flag == 1 )); then
            for i in "${content[@]}"; do
                echo "$i"
            done
            flag=0
        fi
        content=()
    fi

    if [[ "$line" == From:* ]]; then
        SENDER=$(echo "$line" | cut -d' ' -f2 | cut -d'@' -f1)

        # Check if the sender is "enemy"
        if [[ "$SENDER" == "$SENDER_ALERT" ]]; then
            echo "ALERT: Email received from $SENDER!"
            flag=1
        fi
    fi

done
