#!/bin/bash

# Reset
Color_Off='\033[0m'

Bold=$'\033[1m'
RedBold=$'\033[1;31m'
GreenBold=$'\033[1;32m'


printf "${Bold}%s${Color_Off}\n" "Clean Netdata.."

sudo systemctl stop netdata 2>/dev/null

sudo systemctl disable netdata 2>/dev/null

sudo apt-get purge -y netdata

sudo apt-get autoremove --purge -y

# Configuraciones sobrantes
sudo rm -rf /etc/netdata
sudo rm -rf /var/log/netdata
sudo rm -rf /var/lib/netdata
sudo rm -rf /var/cache/netdata
sudo rm -f /etc/apt/sources.list.d/*netdata*
sudo rm -f /etc/apt/trusted.gpg.d/*netdata*
sudo rm -rf /run/systemd/journal.netdata
sudo apt-get update
printf "${GreenBold}%s${Color_Off}\n" "Netdata removed cleanly."
