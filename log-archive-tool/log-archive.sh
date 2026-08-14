#!/bin/bash
archive_logs(){

	directory="$1"
	
	if [ -n "$2" ]; then

	tar -czf "$2/logs_archive_$(date +"%Y%m%d_%H%M%S")".tar.gz "$directory/"
	else
	mkdir -p logs-archives
	tar -czf "logs-archives/logs_archive_$(date +"%Y%m%d_%H%M%S")".tar.gz "$directory/"

	fi
}


extract_logs(){
   	archive="$1"

	if [ -n "$2" ]; then

        tar -xzvf "$archive" -C "$2"
	else
	mkdir -p logs_archives_extract
	tar -xzvf "$archive" -C "logs_archives_extract"
	
	fi
}



case "$1" in
    -a)
        archive_logs "$2" "$3"
        ;;
    -e)
        extract_logs "$2" "$3"
        ;;
    *)
        echo "Uso: $0 {-a|-e} ..."
        ;;
esac 
