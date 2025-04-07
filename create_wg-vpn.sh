#!/bin/bash
set -e

# WireGuard Easy Auto-Deploy Script (preconfigurat)

# Configuració fixa (pots canviar-la aquí)
WG_HOST="172.30.15.10"
LANG="ca"
PORT="51821"
WG_PORT="51820"
WG_DEFAULT_ADDRESS="10.8.0.0"
WG_DEFAULT_DNS="192.168.30.2, 1.1.1.1"
UI_TRAFFIC_STATS="true"
UI_CHART_TYPE="2"
WG_ALLOWED_IPS="172.18.0.0/16"

# Crear fitxer docker-compose.yml
create_docker_compose() {
  cat > docker-compose.yml << EOF
version: '3'

volumes:
  etc_wireguard:

services:
  wg-easy:
    image: ghcr.io/wg-easy/wg-easy
    container_name: wg-easy
    environment:
      - LANG=$LANG
      - WG_HOST=$WG_HOST
      - PORT=$PORT
      - WG_PORT=$WG_PORT
      - WG_DEFAULT_ADDRESS=$WG_DEFAULT_ADDRESS
      - WG_DEFAULT_DNS=$WG_DEFAULT_DNS
      - UI_TRAFFIC_STATS=$UI_TRAFFIC_STATS
      - UI_CHART_TYPE=$UI_CHART_TYPE
      - WG_ALLOWED_IPS=$WG_ALLOWED_IPS
    volumes:
      - etc_wireguard:/etc/wireguard
    ports:
      - "$WG_PORT:$WG_PORT/udp"
      - "$PORT:$PORT/tcp"
    restart: unless-stopped
    cap_add:
      - NET_ADMIN
      - SYS_MODULE
    sysctls:
      - net.ipv4.ip_forward=1
      - net.ipv4.conf.all.src_valid_mark=1
EOF
}

# Iniciar servei si no està ja funcionant
start_container() {
  if docker ps --format '{{.Names}}' | grep -q '^wg-easy$'; then
    echo "✅ WireGuard Easy ja està funcionant!"
    echo "🌐 Accedeix a: http://$WG_HOST:$PORT"
    exit 0
  fi

  echo "🚀 Instal·lant WireGuard Easy..."
  mkdir -p wireguard
  create_docker_compose

  echo "✅ Fitxer docker-compose.yml creat correctament."
  docker-compose up -d

  echo "✅ WireGuard Easy està funcionant."
  echo "🌐 Accedeix a la interfície web a: http://$WG_HOST:$PORT"
}

# Execució principal
echo "=== Instal·lació automàtica de WireGuard Easy ==="
create_docker_compose
start_container
