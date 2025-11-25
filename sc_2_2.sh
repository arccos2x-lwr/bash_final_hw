#!/bin/bash

DIR_NAME=$(dirname "${BASH_SOURCE[0]}")
LOG_DIR="$DIR_NAME/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/log_2_2.log"

NOW=$(date '+%d.%m.%Y %H:%M:%S')

rows_to_devices() {
    local rows="/proc/bus/input/devices"
    local I_row=""
    local N_row=""
    local counter=0

    # Проверяем существование файла
    if [ ! -f "$rows" ]; then
        echo "Файл $rows не найден"
        return 1
    fi

    echo "name|bustype|vendor|product|version"

    while IFS= read -r row; do
        case "$row" in
            I:*)
                I_row="$row"
                ;;
            N:*)
                N_row="$row"
                ;;
            "")
                # Пустая строка - конец блока устройства
                if [ -n "$I_row" ] && [ -n "$N_row" ]; then
		            local name=$(echo "$N_row" | cut -d= -f2- | sed 's/^ *//; s/^"//; s/"$//')
                    local bustype=$(echo "$I_row" | grep -o 'Bus=[0-9a-fA-F]*' | cut -d= -f2)
                    local vendor=$(echo "$I_row" | grep -o 'Vendor=[0-9a-fA-F]*' | cut -d= -f2)
                    local product=$(echo "$I_row" | grep -o 'Product=[0-9a-fA-F]*' | cut -d= -f2)
                    local version=$(echo "$I_row" | grep -o 'Version=[0-9a-fA-F]*' | cut -d= -f2)
		            echo "$name|$bustype|$vendor|$product|$version"
                fi
                # Сбрасываем переменные для следующего устройства
                I_row=""
                N_row=""
                ;;
        esac
    done < "$rows"

}

TEMP_FILE=$(mktemp)

echo $NOW > $TEMP_FILE
rows_to_devices >> $TEMP_FILE
cat "$TEMP_FILE" | column -t -s "|" > $LOG_FILE
