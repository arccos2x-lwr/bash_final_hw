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

# Функция для проверки существования интерфейса
check_interface_exists() {
    local INTERFACE="$1"
    if ! ip link show "$INTERFACE" &> /dev/null; then
        echo "Interface does not exist"
        exit 1
    fi
}


#основной обработчик
main(){
  check_root

  INTERFACE="$1"
  PREFIX=$(ip a | grep -oP 'inet \K[\d./]+24' | awk -F'[./]' '{print $1"."$2}')

  # help, чтоб не забыть/посмотреть
  if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
      echo ""
      echo "<INTERFACE>"
      echo ""
      echo "\$INTERFACE name (example, eth0)"
      echo ""
      exit 1
  fi

  if [[ -z "$INTERFACE" ]]; then
      echo "\$INTERFACE must be passed as second positional argument"
      exit 1
  fi
  if ! check_interface_exists "$INTERFACE"; then
      exit 1
  fi

  # Валидация PREFIX (формат: xxx.xxx)
  if [[ ! "$PREFIX" =~ ^[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    echo "PREFIX error"
    exit 1
  fi

  SUBNET_START=1
  SUBNET_END=255
  HOST_START=1
  HOST_END=255

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
