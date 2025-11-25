#!/bin/bash

DIR_NAME=$(dirname "${BASH_SOURCE[0]}")
LOG_DIR="$DIR_NAME/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/log_1_5.log"

NOW=$(date '+%d.%m.%Y %H:%M:%S')

SILENT_MODE=false


select_parameters() {
    echo "=== Выбор параметров для мониторинга ==="
    echo "Выберите от 1 до 4 параметров (через пробел):"
    echo "1) cmdline  - Командная строка"
    echo "2) environ  - Переменные окружения" 
    echo "3) limits   - Лимиты ресурсов"
    echo "4) mounts   - Точки монтирования"
    echo "5) status   - Статус процесса"
    echo "6) cwd      - Рабочая директория"
    echo "7) fd       - Файловые дескрипторы"
    echo "8) fdinfo   - Информация о файловых дескрипторах"
    echo "9) root     - Корневая директория"
    echo ""
    echo -n "Ваш выбор (например: 1 3 5 6): "
    
    read -r selected
    echo ""
    
    # Преобразуем ввод в массив
    IFS=' ' read -ra choices <<< "$selected"
    
    # Проверяем корректность выбора
    if [ ${#choices[@]} -lt 4 ]; then
        echo "Ошибка: нужно выбрать не менее 4 параметров!"
        exit 1
    fi
    
    # Создаем массив выбранных параметров
    selected_params=()
    for choice in "${choices[@]}"; do
        case $choice in
            1) selected_params+=("cmdline") ;;
            2) selected_params+=("environ") ;;
            3) selected_params+=("limits") ;;
            4) selected_params+=("mounts") ;;
            5) selected_params+=("status") ;;
            6) selected_params+=("cwd") ;;
            7) selected_params+=("fd") ;;
            8) selected_params+=("fdinfo") ;;
            9) selected_params+=("root") ;;
            *) 
                echo "Ошибка: неверный выбор '$choice'"
                exit 1
                ;;
        esac
    done
    
    echo "Выбраны параметры: ${selected_params[*]}"
    echo ""
}


get_process_info() {
    local pid=$1
    local params=("${@:2}")
    local result="$pid"
    name=$(grep "Name:" "/proc/$pid/status" | cut -f2 2>/dev/null || echo "N/A")
    result+="|$name"
    
    for param in "${params[@]}"; do
        case $param in
            cmdline)
                if [ -r "/proc/$pid/cmdline" ]; then
                    cmdline=$(tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null | head -c 100)
                    [ -z "$cmdline" ] && cmdline="[kernel process]"
                    result+="|${cmdline:0:30}"
                else
                    result+="|N/A"
                fi
                ;;
            environ)
                if [ -r "/proc/$pid/environ" ]; then
                    env_count=$(tr '\0' '\n' < "/proc/$pid/environ" 2>/dev/null | wc -l)
                    result+="|$env_count"
                else
                    result+="|N/A"
                fi
                ;;
            limits)
                if [ -r "/proc/$pid/limits" ]; then
                    max_files=$(grep "Max open files" "/proc/$pid/limits" | awk '{print $4}' 2>/dev/null || echo "N/A")
                    result+="|$max_files"
                else
                    result+="|N/A"
                fi
                ;;
            mounts)
                if [ -r "/proc/$pid/mounts" ]; then
                    mounts_count=$(wc -l < "/proc/$pid/mounts" 2>/dev/null || echo "0")
                    result+="|$mounts_count"
                else
                    result+="|N/A"
                fi
                ;;
            status)
                if [ -r "/proc/$pid/status" ]; then
                    state=$(grep "State:" "/proc/$pid/status" | cut -f2 2>/dev/null || echo "N/A")
                    result+="|$state"
                else
                    result+="|N/A"
                fi
                ;;
            cwd)
                if [ -e "/proc/$pid/cwd" ]; then
                    cwd=$(readlink "/proc/$pid/cwd" 2>/dev/null || echo "N/A")
                    result+="|$(basename "$cwd" 2>/dev/null)"
                else
                    result+="|N/A"
                fi
                ;;
            fd)
                if [ -d "/proc/$pid/fd" ]; then
                    fd_count=$(ls "/proc/$pid/fd" 2>/dev/null | wc -l)
                    result+="|$fd_count"
                else
                    result+="|N/A"
                fi
                ;;
            fdinfo)
                if [ -d "/proc/$pid/fdinfo" ]; then
                    fdinfo_count=$(ls "/proc/$pid/fdinfo" 2>/dev/null | wc -l)
                    result+="|$fdinfo_count"
                else
                    result+="|N/A"
                fi
                ;;
            root)
                if [ -e "/proc/$pid/root" ]; then
                    root=$(readlink "/proc/$pid/root" 2>/dev/null || echo "N/A")
                    result+="|$(basename "$root" 2>/dev/null)"
                else
                    result+="|N/A"
                fi
                ;;
        esac
    done
    
    echo "$result"
}

# Проверяем параметры командной строки
if [ "$1" = "--silent" ] || [ "$1" = "-s" ]; then
    SILENT_MODE=true
    # В silent режиме используем фиксированный набор из 4 параметров
    selected_params=("cmdline" "status" "limits" "cwd")
    echo "Режим: SILENT - автоматически выбраны 4 параметра"
    echo "Используются: ${selected_params[*]}"
else
    select_parameters
fi

TEMP_FILE=$(mktemp)
echo "timestamp: $NOW" > $TEMP_FILE
echo "PID|Name|$(IFS='|'; echo "${selected_params[*]}")" >> $TEMP_FILE

counter=0
for pid_dir in /proc/[0-9]*/; do
    if [ -d "$pid_dir" ]; then
        pid=$(basename "$pid_dir")
        
 	if awk -v check_pid="$pid" '$1 == check_pid {found=1} END {exit !found}' "$LOG_FILE" 2>/dev/null; then
            continue
        fi

        process_info=$(get_process_info "$pid" "${selected_params[@]}")
        echo "$process_info" >> $TEMP_FILE
        
        ((counter++))
    fi
done

cat "$TEMP_FILE" | column -t -s "|" >> $LOG_FILE
rm -f "$TEMP_FILE"
