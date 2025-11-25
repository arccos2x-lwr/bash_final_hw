#!/bin/bash

DIR_NAME=$(dirname "${BASH_SOURCE[0]}")
LOG_DIR="$DIR_NAME/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/log_2_3.log"

NOW=$(date '+%d.%m.%Y %H:%M:%S')

rows_to_devices() {
    local rows="/proc/bus/input/devices"
    local I_row=""
    local N_row=""

    if [ ! -f "$rows" ]; then
        echo "Файл $rows не найден"
        return 1
    fi

    echo "bustype|vendor|product|version|name"

    while IFS= read -r row; do
        case "$row" in
            I:*)
                I_row="$row"
                ;;
            N:*)
                N_row="$row"
                ;;
            "")
                if [ -n "$I_row" ] && [ -n "$N_row" ]; then
                    local name=$(echo "$N_row" | cut -d= -f2- | sed 's/^ *//; s/^"//; s/"$//')
                    local bustype=$(echo "$I_row" | grep -o 'Bus=[0-9a-fA-F]*' | cut -d= -f2 || echo "N/A")
                    local vendor=$(echo "$I_row" | grep -o 'Vendor=[0-9a-fA-F]*' | cut -d= -f2 || echo "N/A")
                    local product=$(echo "$I_row" | grep -o 'Product=[0-9a-fA-F]*' | cut -d= -f2 || echo "N/A")
                    local version=$(echo "$I_row" | grep -o 'Version=[0-9a-fA-F]*' | cut -d= -f2 || echo "N/A")
		    
		    echo "$bustype|$vendor|$product|$version|$name"
                fi
                I_row=""
                N_row=""
                ;;
        esac
    done < "$rows"
}

check_new() {
    local old_list="$1"  # Старый файл (форматированный)
    local new_list="$2"  # Новый файл (с разделителями |)
    local show_header=true # Выводить ли заголовок, если найдены новые устройства
    
    if [ ! -f "$old_list" ]; then
        echo "Старый файл не найден, все устройства новые"
        return 0
    fi
    
    # Читаем НОВЫЕ устройства и проверяем их в СТАРОМ файле
    while IFS='|' read -r bustype vendor product version name; do
        # Пропускаем заголовок
        if [[ "$bustype" == "bustype" || -z "$bustype" ]]; then
            continue
        elif echo "$bustype" | grep -q "^timestamp"; then
            local header="$bustype"
            continue
        fi
        
        # Проверяем в старом файле
        if awk -v check_bustype="$bustype" -v check_vendor="$vendor" -v check_product="$product" -v check_version="$version" \
            '($1 == check_bustype && $2 == check_vendor && $3 == check_product && $4 == check_version) {found=1} END {exit !found}' "$old_list" 2>/dev/null; then
            continue
        else
            # Если не нашли - это новое устройство
            if [[ "$show_header" == true ]]; then
            	echo "$header"
            	echo "bustype|vendor|product|version|name"
            	show_header=false
	          fi
            echo "$bustype|$vendor|$product|$version|$name"
        fi
    done < "$new_list"
}

TEMP_FILE=$(mktemp)
TEMP_FILE2=$(mktemp)

echo "timestamp $NOW" > "$TEMP_FILE"
rows_to_devices >> "$TEMP_FILE"

if [ ! -f "$LOG_FILE" ]; then
    # Первый запуск - создаем лог со всеми устройствами
    echo "Первый запуск - создаем лог"
    cat "$TEMP_FILE" | column -t -s "|" > "$LOG_FILE"
else
    # Последующие запуски - ищем новые устройства
    echo "Поиск новых устройств..."
    check_new "$LOG_FILE" "$TEMP_FILE" >> "$TEMP_FILE2"
    
    # Если есть новые устройства, добавляем их в лог
    if [ -s "$TEMP_FILE2" ] && [ $(wc -l < "$TEMP_FILE2") -gt 1 ]; then
        echo "" >> "$LOG_FILE"
        #echo "bustype|vendor|product|version|name" >> "$LOG_FILE" 
        cat "$TEMP_FILE2" | column -t -s "|" >> "$LOG_FILE"
        echo "Добавлены новые устройства"
    else
        echo "Новых устройств не обнаружено"
        # Добавляем только timestamp для отметки проверки
        echo "" >> "$LOG_FILE"
        echo "timestamp $NOW - no new devices" | column -t -s "|" >> "$LOG_FILE"
    fi
fi

rm -f "$TEMP_FILE" "$TEMP_FILE2"
