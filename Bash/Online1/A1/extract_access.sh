#!/usr/bin/bash


## First give execute permission to the script: chmod +x extract_access.sh
## RUN: ./extract_access.sh access.log "Login" "00-23" | sort | uniq -c | sort -nr | sed 's/^ *//' | cut -d' ' -f1,2
## The part after sort -nr just cleans up the output to match the expected output

if [ $# -ne 3 ]; then
    echo "Usage: ./extract_access.sh <log_file> <access_type> <timerange>"
    exit 1
fi

log_file=$1
access_type=$2
start_hh=$(echo "$3" | cut -d'-' -f1)
end_hh=$(echo "$3" | cut -d'-' -f2)

# Convert hours to integers
start_hh=$((10#$start_hh))
end_hh=$((10#$end_hh))

# Read and filter log file
while read -r line; do
    timestamp=$(echo "$line" | cut -d' ' -f2)
    username=$(echo "$line" | cut -d' ' -f3)
    action=$(echo "$line" | cut -d' ' -f4-) # Notice the - after 4
    hh=$(echo "$timestamp" | cut -d':' -f1)
    hh=$((10#$hh))

    # Check if action matches and time is within range
    if [[ "$action" == "$access_type" ]] && (( hh >= start_hh && hh <= end_hh )); then
        echo "$username $action"
    fi
done < "$log_file"
