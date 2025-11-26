#!/bin/bash
PREFIX="${1:-NOT_SET}"
INTERFACE="$2"

# Функция для проверки привилегий root
check_root(){
	if [[ "$EUID" -ne 0 ]]; then
	echo "Please run as root"
	  exit
	fi
}

# Функция для проверки октета
check_octet(){
  local octet="$1"
  local octet_name="$2"

  if [[ ! "$octet" =~ ^[0-9]{1,3}$ ]] || [[ "$octet" -gt 255 ]]; then
      echo "Error in $octet_name, available range 0-255"
      return 1
  fi

  return 0
}

# Функция для проверки существования интерфейса
check_interface_exists() {
    local INTERFACE="$1"
    if ! ip link show "$INTERFACE" &> /dev/null; then
        echo "Interface \$INTERFACE does not exist"
        exit 1
    fi
}


#основной обработчик
main(){
  check_root

  PREFIX="${1:-NOT_SET}"
  INTERFACE="$2"
  SUBNET="${3:-ALL}"
  HOST="${4:-ALL}"

  # help, чтоб не забыть/посмотреть
  if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
      echo ""
      echo "<PREFIX> <INTERFACE> [SUBNET] [HOST]"
      echo ""
      echo "\$PREFIX consists of '\$PREFIX_1 . \$PREFIX_2' , must be xxx.xxx (example, 192.168)"
      echo "\$INTERFACE name (example, eth0)"
      echo "\$SUBNET - optional, range 0-255, default range is 1..255"
      echo "\$HOST - optional, range 0-255, default range is 1..255"
      echo ""
      exit 1
  fi

  [[ "$PREFIX" = "NOT_SET" ]] && { echo "\$PREFIX must be passed as first positional argument"; exit 1; }
  if [[ -z "$INTERFACE" ]]; then
      echo "\$INTERFACE must be passed as second positional argument"
      exit 1
  fi
  if ! check_interface_exists "$INTERFACE"; then
      exit 1
  fi


  # Валидация PREFIX (формат: xxx.xxx)
  if [[ ! "$PREFIX" =~ ^[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    echo "\$PREFIX format must be xxx.xxx (example, 192.168)"
    exit 1
  fi

  # Извлечение частей PREFIX для валидации
  IFS='.' read -r PREFIX1 PREFIX2 <<< "$PREFIX"
  if ! check_octet "$PREFIX1" "\$PREFIX_1" || ! check_octet "$PREFIX2" "\$PREFIX_2"; then
    exit 1
  fi

  # Проверка SUBNET
  SUBNET_START=1
  SUBNET_END=255
  if [[ "$SUBNET" != "ALL" ]]; then
    if ! check_octet "$SUBNET" "\$SUBNET"; then
      exit 1;
    fi
    SUBNET_START="$SUBNET"
    SUBNET_END="$SUBNET"
  fi

  # Проверка SUBNET
    HOST_START=1
    HOST_END=255
    if [[ "$HOST" != "ALL" ]]; then
      if ! check_octet "$HOST" "\$HOST"; then
        exit 1;
      fi
      HOST_START="$HOST"
      HOST_END="$HOST"
    fi


  for SUBNET in $(seq $SUBNET_START "$SUBNET_END")
  do
  	for HOST in $(seq "$HOST_START" "$HOST_END")
  	do
  		echo "[*] IP : ${PREFIX}.${SUBNET}.${HOST}"
  		arping -c 3 -i "$INTERFACE" "${PREFIX}.${SUBNET}.${HOST}" 2> /dev/null
  	done
  done
}

main "$@"
