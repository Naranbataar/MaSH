#!/bin/sh

ws_start(){
    dir="$(pwd)"
    rm -rf "$1" && mkdir "$1"
    trap "rm -rf '$1'" EXIT
    cd "$1"

    mkdir "stat" "config" "event" "handler" "listener"
    printf "%s\n" "$2" > config/token
    printf "%s\n" "$3" > config/bot
    printf "%s\n" "$4" > config/shard_no
    printf "%s\n" "$5" > config/shard_count
    printf "%s\n" "$6" > config/guild_subscriptions

    url="wss://gateway.discord.gg/?v=6&encoding=json"
    (nc -klU "stat/socket" \
     | websocat -B 67108864 -tnE "$url" \
     | (for x in $(seq 256); do
           printf '%s\n' "{\"op\":-1, \"d\":null}"
        done; cat) \
     | while read -r event; do
           file="event/$(uuidgen)"
           printf '%s\n' "$event" > "$file"
           printf '%s\n' "$file"
       done \
     | parallel -j200 --lb -q -N1 dispatch) &

    printf '%s\n' "$!" > "stat/proc"
    cd "$dir"
}

ws_send(){
    [ -z "$1" ] && exit 1
    read -r text
    printf '%s\n' "{\"op\":$1,\"d\":$text}" | nc -U stat/socket
}

ws_kill(){
    kill "$(cat "stat/proc")"
}

ewait(){
    [ -z "$1" ] && exit 1
    pipe="listener/$(uuidgen)"
    rm -f "$pipe" && mkfifo "$pipe"
    tail -f > "$pipe" &
    trap "kill -9 $! 2> /dev/null; rm -f '$pipe'" EXIT

    query="fromstream(0|truncate_stream(inputs)) | select($1)"
    timeout "${2:-0}" cat "$pipe" \
    | jq -cM --stream --unbuffered "$query" \
    | while IFS= read -r event || [ -n "$event" ]; do
        printf '%s\n' "$event"
        exit
    done
}
