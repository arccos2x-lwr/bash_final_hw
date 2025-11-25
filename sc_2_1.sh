#!/bin/bash

DIR_NAME=$(dirname "${BASH_SOURCE[0]}")
LOG_DIR="$DIR_NAME/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/log_2_1.log"

NOW=$(date '+%d.%m.%Y %H:%M:%S')

echo $NOW > $LOG_FILE

#counter=0
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

    echo "Список устройств ввода:"

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
                    ((counter++))
                    echo "Устройство #$counter:"
                    echo "$I_row"
                    echo "$N_row"
                    echo ""
                fi
                # Сбрасываем переменные для следующего устройства
                I_row=""
                N_row=""
                ;;
        esac
    done < "$rows"

    echo "Всего устройств: $counter"
}

rows_to_devices > $LOG_FILE
