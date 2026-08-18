#!/bin/bash

set -e
# Reset
Color_Off='\033[0m'       # Text Reset

Bold=$'\033[1m'
YellowBold=$'\033[1;33m'
RedBold=$'\033[1;31m'
GreenBold=$'\033[1;32m'

# Check if the script is running as root or if passwordless sudo is available

if [[ ! $EUID -ne 0 ]] && ! sudo -n -v &>/dev/null; then
	printf "${RedBold}Error${Color_Off} %s\n" "Root or passwordless sudo permissions are needed"
        exit 1
fi

	printf "${YellowBold}%s${Color_Off}\n" "Checking if Netdata is installed..."

if command -v netdata >/dev/null 2>&1; then
	printf "%s\n" "Netdata is already installed."
	exit 1
fi
	printf "${GreenBold}%s${Color_Off}\n" "Update packages [1]"
	sudo apt update -qq
	
	printf "${GreenBold}%s${Color_Off}\n" "Installing Netdata... [2]"

	curl -fsSL -o /tmp/netdata-kickstart.sh https://get.netdata.cloud/kickstart.sh &&
	sudo sh /tmp/netdata-kickstart.sh --disble-telemetry --non-interactive --release-channel stable
	
	printf "${GreenBold}%s${Color_Off}\n" "Netdata installed successfully."

	printf "${GreenBold}%s${Color_Off}\n" "Creating Alerts [3]"
	
	printf "${YellowBold}%s${Color_Off}\n" "Alert CPU"

sudo tee /etc/netdata/health.d/cpu-alert.conf > /dev/null <<'EOF'
alarm: cpu_usage
   on: system.cpu
class: Utilization
type: System
component: CPU
os: linux
lookup: average -2m unaligned of user,system,softirq,irq,guest
units: %
every: 10s
warn: $this > (($status >= $WARNING) ? (75) : (85))
crit: $this > (($status >= $CRITICAL) ? (85) : (95))
delay: down 5m
info: CPU usage 
to: sysadmin
EOF

	 printf "${YellowBold}%s${Color_Off}\n" "Alert RAM"

sudo tee /etc/netdata/health.d/memory-alert.conf > /dev/null <<'EOF'
alarm: mem_usage
   on: system.ram
class: Utilization
type: System
component: Memory
os: linux
calc: $used * 100 / ($used + $cached + $free + $buffers)
units: %
every: 10s
warn: $this > (($status >= $WARNING) ? (80) : (90))
crit: $this > (($status >= $CRITICAL) ? (80) : (98))
delay: down 15m
info: Memory  usage
to: sysadmin
EOF

         printf "${YellowBold}%s${Color_Off}\n" "Alert Disk Space"

sudo tee /etc/netdata/health.d/disk-alert.conf > /dev/null <<'EOF'
template: disk_space
   on: disk.space
class: Utilization
type: System
component: Disk Space
os: linux
calc: $user * 100 / ($user + $available)
units: %
every: 30s
warn: $this > 80
crit: $this > 95
delay: down 10m
info: Almost full disk
to: sysadmin
EOF

sudo netdatacli reload-health

	printf "${GreenBold}%s${Color_Off}\n" "Netdata in local:http://localhost:19999"
	printf "${GreenBold}%s${Color_Off}\n" "Netdata in cloud:http://IP_PRIVATE:19999"
