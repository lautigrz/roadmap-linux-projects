#!/bin/bash

# Reset
Color_Off='\033[0m'       # Text Reset

# Regular Colors
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Bright_Green=$'\033[92m'
Yellow='\033[0;33m'       # Yellow
Cyan='\033[0;36m'         # Cyan
White='\033[0;37m'        # White
DarkGray='\033[1;30m'     # DarkGray

Bold=$'\033[1m'
Underline=$'\033[4m'
CyanBold=$'\033[1;36m'
GreenBold=$'\033[1;32m'
YellowBold=$'\033[1;33m'
RedBold=$'\033[1;31m' 
cpu_usage(){
	cpu_idle=$(top -bn2 -d1 | grep "Cpu" | sed 1d | awk -F "," '{print $4}' | awk '{print $1}')
	cpu_used=$(awk "BEGIN {print 100 - $cpu_idle}")
	
	printf "${CyanBold}CPU:${White}"
	progress_bar "$cpu_used"
	
	printf "\n"	
	
}


mem_usage(){

	mem_info=$(free -m | grep "Mem" | awk '{print $2,$3,$4,$7}')

	mem_total=$(echo "$mem_info" | awk '{print $1}')

	mem_usage_info=$(echo "$mem_info" | awk '{print $2}')

	mem_free=$(echo "$mem_info" | awk '{print $3}')
	
	mem_available=$(echo "$mem_info" | awk '{print $4}')

	mem_percentage_usage=$((mem_usage_info * 100 / mem_total))

	printf "${CyanBold}RAM:${White}"
	
	progress_bar "$mem_percentage_usage"
	
	printf " ${CyanBold}Available: ${Color_Off}${mem_available} ${CyanBold}Total: ${Color_Off}${mem_total}"
	
	printf "\n"
}

top_5_process(){
    cpu_process=$(ps -eo pid,%cpu,comm --sort=-%cpu | head -6 | tail -5)
    ram_process=$(ps -eo %mem,comm --sort=-%mem | head -6 | tail -5)

    printf "${CyanBold}%-42s %-60s${Color_Off}\n" \
    "Top 5 CPU Process" "Top 5 RAM Process"
    
printf "%-10s %-10s %-20s %-10s %-20s\n" \
        "PID" "CPU%" "COMMAND" "MEM%" "COMMAND"

    paste <(echo "$cpu_process") <(echo "$ram_process") |
    while read -r pid cpu comm mem ram_comm; do
        printf "${YellowBold}%-10s${Color_Off} %-10s %-20s %-10s %-20s\n" \
            "$pid" "$cpu" "$comm" "$mem" "$ram_comm"
    done
}

progress_bar(){
	percentage=$(printf '%.0f\n' $1)
	bar_count=$((percentage / 2))
	
	if [ "$bar_count" -lt 35 ]; then
	   color=$GreenBold
	elif [ "$bar_count" -lt 45 ]; then
	   color=$YellowBold
	else
	   color=$RedBold
	fi
	

	printf "$White[${color}"	
	printf '%*s' "$bar_count" '' | tr ' ' '|'
	printf '%*s' $((50 - bar_count)) ' '
	printf "${DarkGray}${percentage}%%${White}]${Color_Off}"

}


disk_usage(){

	disk_info=$(df -h / | tail -1 | awk '{print $2,$4,$5}')
	
	size=$(echo "$disk_info" | awk '{print $1}')
	avail=$(echo "$disk_info" | awk '{print $2}')
	use=$(echo "$disk_info" | awk '{print $3}' | sed s/%// | awk '{print $1}' )
	
	printf "${CyanBold}DISK:${White}"
	progress_bar "$use"
	
 
   printf " ${CyanBold}Available: ${Color_Off}${avail} ${CyanBold}Total: ${Color_Off}${size}"
	
	printf "\n"
}
	

cpu_usage
mem_usage
disk_usage
top_5_process
