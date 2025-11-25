#!/bin/bash

DIR_NAME=$(dirname "${BASH_SOURCE[0]}")
LOG_FILE="$DIR_NAME/logs/log_1_2.log"

NOW=$(date '+%d.%m.%Y %H:%M:%S')

echo $NOW > $LOG_FILE

counter=0

for dir in /proc/[0-9]*/; do
	if [ -d "$dir" ]; then
		pid=$(basename "$dir")
		link=$(readlink "/proc/$pid/exe" 2>/dev/null || echo "-")
		echo "$pid: $link" >> $LOG_FILE
		((counter++))
	fi
done

echo "done, $counter occurs"