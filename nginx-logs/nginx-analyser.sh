
Bold=$'\033[1m'
Color_Off='\033[0m'     

top_5_ip(){
  	
	result=$( awk '{ ips[$1]++ } END { for (ip in ips) print ip, ips[ip] }' "$1" | sort -k2 -nr | head -5 | awk '{print $1 " - " $2}')
	
	printf "${Bold}Top 5 IP addresses with the most requests:${Color_Off}\n"
	printf '%s\n' "$result"
	printf '\n'
}

top_5_path(){

      result=$(awk '
        BEGIN {
            verbos["GET"]=1; verbos["POST"]=1; verbos["PUT"]=1
            verbos["DELETE"]=1; verbos["PATCH"]=1; verbos["OPTIONS"]=1
        }
        {
            for (i = 1; i <= NF; i++) {
                campo = $i
                gsub(/"/, "", campo)
                if (campo in verbos) {
                    path = $(i+1)
                    gsub(/"/, "", path)
                    paths[path]++
                }
            }
        }
        END {
            for (p in paths) print p, paths[p]
        }' "$1" | sort -k2 -nr | head -5 | awk '{print $1 " - " $2}')
        printf "${Bold}Top 5 most requested paths:${Color_Off}\n"
        printf '%s\n' "$result"
        printf '\n'
}

top_5_status(){
        result=$(awk '
        BEGIN {
            httpVersion["HTTP/1.1"]=1; httpVersion["HTTP/2"]=1; httpVersion["HTTP/3"]=1
        }
        {
            for (i = 1; i <= NF; i++) {
                campo = $i
                gsub(/"/, "", campo)
                if (campo in httpVersion) {
                    code = $(i+1)
                    gsub(/"/, "", code)
                    status[code]++
                }
            }
        }
        END {
            for (c in status) print c, status[c]
        }' "$1" | sort -k2 -nr | head -5 | awk '{print $1 " - " $2}')
        printf "${Bold}Top 5 response status codes:${Color_Off}\n"
        printf '%s\n' "$result"
        printf '\n'
}

top_5_user_agents(){
	 result=$(awk -F'"' '{ agentes[$6]++ } END { for (a in agentes) print agentes[a], "-", a }' "$1" | sort -rn | head -5)
        printf "${Bold}Top 5 user agents:${Color_Off}\n"
        printf '%s\n' "$result"
        printf '\n'

}

top_5_non_http(){
        count=$(awk -F'"' '{ print $2 }' "$1" | grep -vcE '^(GET|POST|PUT|DELETE|PATCH|OPTIONS|HEAD|CONNECT) ')
        printf "${Bold}Non-HTTP / suspicious requests:${Color_Off}\n"
        printf '%s requests out of total\n' "$count"
        printf '\n'
}
top_5_ip "$1"
top_5_path "$1"
top_5_status "$1"
top_5_user_agents "$1"
top_5_non_http "$1"
