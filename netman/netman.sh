#!/bin/bash

set -e

NETMAN_DIR="/home/${USER}/netman"
NETMAN_ENV_FILE="netman.env"

cd $NETMAN_DIR
. ./${NETMAN_ENV_FILE}


function configureFirewall() {

  echo "Configuring firewall..."

  sudo apt install ufw -y
  sudo ufw allow ssh
  sudo ufw allow 5900/tcp
  sudo ufw allow "${NGINX_PROXY_MANAGER_HTTP_PORT}/tcp"
  sudo ufw allow "${NGINX_PROXY_MANAGER_HTTPS_PORT}/tcp"
  sudo ufw allow "${NGINX_PROXY_MANAGER_ADMIN_PORT}/tcp"
  sudo ufw allow "${PIHOLE_DNS_PORT}/tcp"
  sudo ufw allow "${PIHOLE_DNS_PORT}/udp"
  sudo ufw allow "${PIHOLE_DHCP_PORT}/udp"
  sudo ufw allow "${UNIFI_STUN_PORT}/udp"
  sudo ufw allow "${UNIFI_SPEEDTEST_PORT}/tcp"
  sudo ufw allow "${UNIFI_DEVICE_DISCOVERY_PORT}/udp"
  sudo ufw enable
  sudo ufw status

  echo "Completed configuring firewall!"

}

function createBackupDirs() {

  echo "Creating volume backups directory..."

  mkdir -p "${BACKUPS_DIR}"

  echo "Completed creating volume backups directory!"

}

function startServices() {

  docker compose --env-file "./${NETMAN_ENV_FILE}" up -d

}

function stopServices() {

  docker compose --env-file "./${NETMAN_ENV_FILE}" down

}

function updateServices() {

  stopServices

  docker compose --env-file "./${NETMAN_ENV_FILE}" pull

  startServices

}

case $1 in
  start)
    echo "Starting netman services..."
    startServices
  ;;
  stop)
    echo "Stopping netman services..."
    stopServices
  ;;
  setup)
    echo "Setting up dependencies for netman services..."
    configureFirewall
    createBackupDirs
  ;;
  update)
    echo "Updating services..."
    updateServices
  ;;
  *)
    echo "Unknown argument: $1"
    exit 1
  ;;
esac