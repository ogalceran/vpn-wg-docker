#!/bin/bash

# WireGuard Easy Automation Script

# Define default values
WG_HOST="raspberrypi.local"
LANG="de"
PORT="51821"
WG_PORT="51820"
WG_DEFAULT_ADDRESS="10.8.0.x"
WG_DEFAULT_DNS="1.1.1.1"
UI_TRAFFIC_STATS="true"
UI_CHART_TYPE="2"

# Function to prompt for configuration values
configure() {
  read -p "Enter your host's public address [$WG_HOST]: " input
  WG_HOST=${input:-$WG_HOST}
  
  read -p "Enter language (en, ua, ru, tr, no, pl, fr, de, ca, es, ko, vi, nl, is, pt, chs, cht, it, th, hi) [$LANG]: " input
  LANG=${input:-$LANG}
  
  read -p "Set admin password? (y/n): " set_password
  if [[ $set_password == "y" ]]; then
    read -s -p "Enter password: " password
    echo
    # Generate bcrypt hash (this is simplified, in production use a proper bcrypt tool)
    echo "You'll need to generate a bcrypt hash and add it manually to the docker-compose.yml file"
    echo "Check 'How_to_generate_an_bcrypt_hash.md' for instructions"
  fi
  
  read -p "Web UI port [$PORT]: " input
  PORT=${input:-$PORT}
  
  read -p "WireGuard port [$WG_PORT]: " input
  WG_PORT=${input:-$WG_PORT}
  
  read -p "WireGuard default address range [$WG_DEFAULT_ADDRESS]: " input
  WG_DEFAULT_ADDRESS=${input:-$WG_DEFAULT_ADDRESS}
  
  read -p "WireGuard default DNS [$WG_DEFAULT_DNS]: " input
  WG_DEFAULT_DNS=${input:-$WG_DEFAULT_DNS}
  
  read -p "Enable traffic statistics? (true/false) [$UI_TRAFFIC_STATS]: " input
  UI_TRAFFIC_STATS=${input:-$UI_TRAFFIC_STATS}
  
  read -p "Chart type (0-disabled, 1-Line, 2-Area, 3-Bar) [$UI_CHART_TYPE]: " input
  UI_CHART_TYPE=${input:-$UI_CHART_TYPE}
  
  read -p "Custom allowed IPs (leave empty for default): " WG_ALLOWED_IPS
}

# Function to create Docker Compose file
create_docker_compose() {
  cat > docker-compose.yml << EOF
version: '3'

volumes:
  etc_wireguard:

services:
  wg-easy:
    environment:
      - LANG=$LANG
      # Required host address
      - WG_HOST=$WG_HOST
      # Web UI port
      - PORT=$PORT
      # WireGuard port
      - WG_PORT=$WG_PORT
      # Default IP address range
      - WG_DEFAULT_ADDRESS=$WG_DEFAULT_ADDRESS
      # Default DNS
      - WG_DEFAULT_DNS=$WG_DEFAULT_DNS
      # Enable traffic statistics
      - UI_TRAFFIC_STATS=$UI_TRAFFIC_STATS
      # Chart type
      - UI_CHART_TYPE=$UI_CHART_TYPE
EOF

  # Add optional allowed IPs if specified
  if [ ! -z "$WG_ALLOWED_IPS" ]; then
    echo "      # Allowed IPs" >> docker-compose.yml
    echo "      - WG_ALLOWED_IPS=$WG_ALLOWED_IPS" >> docker-compose.yml
  fi

  # Complete the Docker Compose file
  cat >> docker-compose.yml << EOF
    image: ghcr.io/wg-easy/wg-easy
    container_name: wg-easy
    volumes:
      - etc_wireguard:/etc/wireguard
    ports:
      - "$WG_PORT:$WG_PORT/udp"
      - "$PORT:$PORT/tcp"
    restart: unless-stopped
    cap_add:
      - NET_ADMIN
      - SYS_MODULE
      # - NET_RAW # Uncomment if using Podman 
    sysctls:
      - net.ipv4.ip_forward=1
      - net.ipv4.conf.all.src_valid_mark=1
EOF
}

# Function to set up and start the container
setup_and_start() {
  # Create directory for WireGuard configuration
  mkdir -p wireguard
  
  # Create Docker Compose file
  create_docker_compose
  
  echo "Docker Compose file created successfully."
  echo "You can now run 'docker-compose up -d' to start WireGuard Easy."
  
  # Ask if user wants to start the container now
  read -p "Do you want to start the container now? (y/n): " start_now
  if [[ $start_now == "y" ]]; then
    docker-compose up -d
    echo "WireGuard Easy has been started."
    echo "Access the web UI at: http://$WG_HOST:$PORT"
  fi
}

# Main script execution
echo "=== WireGuard Easy Setup ==="
echo "This script will help you configure and deploy WireGuard Easy using Docker."
echo

# Ask if user wants to configure or use defaults
read -p "Do you want to configure WireGuard (y) or use defaults (n)? " configure_choice
if [[ $configure_choice == "y" ]]; then
  configure
fi

# Set up and start
setup_and_start