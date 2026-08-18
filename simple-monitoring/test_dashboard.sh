#!/bin/bash

# Reset
Color_Off='\033[0m'       

Bold=$'\033[1m'
RedBold=$'\033[1;31m'
GreenBold=$'\033[1;32m'

	
	
	if ! command -v stress >/dev/null 2>&1; then
        printf "${GreenBold}%s${Color_Off}\n" "Installing stress..."
	sudo apt-get update && sudo apt-get install -y stress
        
fi

CORES=$(nproc)

TIMEOUT="60s"

case "$1" in
     -c)
	printf "${RedBold}%s${Color_Off}\n" "Causing stress on the CPU across ${CORES} cores for ${TIMEOUT}..."
        stress --cpu "${CORES}" --timeout "$TIMEOUT"
	;;
     -m)
	printf "${RedBold}%s${Color_Off}\n" "Causing stress on RAM (2GB) for ${TIMEOUT}..."
        stress --vm 2 --vm-bytes 1G --timeout "$TIMEOUT"
	;;
     *)
	printf "${Bold}%s${Color_Off}\n" "Usage: $0 {-c|-m}"
        printf "  -c : Stress 100%% of available CPU cores\n"
        printf "  -m : Stress RAM memory\n"
        exit 1
	;;
esac
