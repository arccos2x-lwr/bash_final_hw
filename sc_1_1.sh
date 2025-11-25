#!/bin/bash

DIR_NAME=$(dirname "${BASH_SOURCE[0]}")
LOG_DIR="$DIR_NAME/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/log_1_1.log"

NOW=$(date '+%d.%m.%Y %H:%M:%S')

echo $NOW > $LOG_FILE

counter=0

for dir in /proc/[0-9]*/; do
	if [ -d "$dir" ]; then
		pid=$(basename "$dir")
		echo "$pid" >> $LOG_FILE
		((counter++))
	fi
done

echo "done, $counter occurs"