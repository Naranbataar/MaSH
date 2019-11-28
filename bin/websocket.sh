#!/bin/sh
. utils.sh
. `which env_parallel.bash`
[ -z "$MASH_STATUS_DIR" ] && MASH_STATUS_DIR='.mash_tmp'

_last_seq(){
    SEQ="$(cat "$MASH_STATUS_DIR/stat/seq_$1" 2> /dev/null)"
    printf '%s\n' "${SEQ:-0}"
}

_dispatch_event(){
    FILE="$1"
    PAYLOAD="$(cat "$FILE")"
    rm -f "$FILE"

    OP="$(printf '%s\n' "$PAYLOAD" | grep -oP '(?<="op":).*?(?=,)')"
    printf '%s\n' "$PAYLOAD" | tee "$EWDS/"* "$EWDG/"* >> /dev/null

    case "$OP" in
    0)
        TSDP='(?<="t":").*?(?=",)|(?<="s":).*?(?=,)|(?<="d":).*'
        TSD="$(printf '%s\n' "$PAYLOAD" | grep -oP "$TSDP" | head --bytes -2)"
        IFS=':' read -r T S D <<-EOF
		$TSD
		EOF

        [ "$T" = 'READY' ] && (printf '%s\n' "$D" \
                                | jq -r '.session_id' > "$SESF")
        [ "$S" != 'null' ] && (printf '%s\n' "$S" > "$SEQF")

        F="MASH_DISPATCH_$T"
        F="$(eval "echo \${$F}")"
        [ -n "$F" ] && "$F" "$D" 1>>/dev/null 2>> "$MASH_STATUS_DIR/log" ;;
    7)
        ws_kill "$SHARD" ;;
    9)
        rm -f "$SESF"
        rm -f "$LOGF"
        ws_kill "$SHARD" ;;
    10)
        token="$MASH_AUTH_TOKEN"
        if [ -f "$SESF" ]; then
            session_id="$(cat "$SESF")"
            seq="$(_last_seq "$SHARD")"
            set_args token session_id seq::@ | ws_send 6 "$SHARD"
        else
            os="linux"
            browser="mash"
            device="mash"
            shard="[$SHARD, $SHARDS]"
            properties="$(set_args '$os:os' '$browser:browser' \
                                   '$device:device')"
            [ "${MASH_AUTH_GS:-0}" = '1' ] && gs='true' || gs='false'
            set_args token properties::@ shard::@ guild_subscriptions:gs:@ \
            | ws_send 2 "$SHARD"
        fi

        WAIT=5
        INTERVAL=$(printf '%s\n' "$PAYLOAD" | jq -r '.d|.heartbeat_interval')
        INTERVAL="$(awk "BEGIN { print ($INTERVAL / 1000) - $WAIT  }")"

        while true; do
            LACK="$(date +%s%N)"
            _last_seq "$SHARD" | ws_send 1 "$SHARD"
            ACK="$(ewait '.op=11' "$WAIT" "$SHARD")"
            if [ -z "$ACK" ]; then
                ws_kill "$SHARD"
                break
            fi
            sleep "$INTERVAL"
        done;;
    esac
}

_ws_shard(){
    SHARD="$1"; SHARDS="$2"
    PIPE="$MASH_STATUS_DIR/pipe/$1"
    rm -f "$PIPE"; mkfifo "$PIPE"

    PROC="$MASH_STATUS_DIR/proc/shard_$SHARD"
    SESF="$MASH_STATUS_DIR/stat/session_$1"
    SEQF="$MASH_STATUS_DIR/stat/seq_$1"
    EWDG="$MASH_STATUS_DIR/wait/@"
    EWDS="$MASH_STATUS_DIR/wait/${SHARD}"
    EVNT="$MASH_STATUS_DIR/event"
    [ ! -d "$EWDS" ] && mkdir "$EWDS"
    [ ! -d "$EVNT" ] && mkdir "$EVNT"

    URL="wss://gateway.discord.gg/?v=6&encoding=json"
    DUMMY="{\"op\":-1, \"d\":null}"; JOBS="${MASH_JOB_LIMIT:-200}"

    (tail -f "$PIPE" | websocat -B 67108864 -tnE "$URL" \
     | (for x in $(seq "$JOBS"); do
           printf '%s\n' "$DUMMY"
       done; cat) \
     | while read -r E; do
           F="$EVNT/$(uuidgen)"
           printf '%s\n' "$E" > "$F"
           printf '%s\n' "$F"
       done \
     | env_parallel -j"$JOBS" --lb -q -N1 _dispatch_event) &

    printf '%s\n' "$!" > "$PROC"
    wait
    return "$?"
}

_shard_loop(){
    until _ws_shard "$1" "$2"; do
        printf 'Shard %s: crashed with exit code %s... Reconnecting...' \
               "$1" "$?" >&2
        sleep 1
    done
}

ws_start(){
    if [ "$(set |(env;cat) | wc -c)" -ge 64000 ]; then
        printf 'Your environment is larger than 64kB,' >&2
        printf " env_parallel can't work\\n" >&2
        printf "Don't source rest or long functions on the main script" >&2
        exit 1
    fi

    [ -z "$MASH_STATUS_DIR" ] && MASH_STATUS_DIR='.mash_tmp'
    rm -rf "$MASH_STATUS_DIR"
    mkdir "$MASH_STATUS_DIR"

    mkdir "$MASH_STATUS_DIR/proc" "$MASH_STATUS_DIR/lock"
    mkdir "$MASH_STATUS_DIR/stat" "$MASH_STATUS_DIR/pipe"
    mkdir "$MASH_STATUS_DIR/wait" "$MASH_STATUS_DIR/wait/@"

    trap "rm -rf '$MASH_STATUS_DIR'; kill 0" EXIT
    export MASH_STATUS_DIR

    if [ "${MASH_AUTH_BOT:-1}" != "0" ]; then
        SHARDS=$(printf " \n" | dapi GET "/gateway/bot" \
                 | jq -r '.shards//empty')
    fi
    SHARDS="${SHARDS:-1}"

    I=0
    while [ "$I" -lt "$SHARDS" ]; do
        _shard_loop "$I" "$SHARDS" &
        I="$(( I + 1 ))"
    done
    wait
}

ws_send(){
    [ -z "$1" ] && exit 1
    read -r TEXT
    PIPE="$MASH_STATUS_DIR/pipe/${2:-0}"
    printf '%s\n' "{\"op\":$1,\"d\":$TEXT}" | dd oflag=nonblock of="$PIPE" \
                                                 status=none
}

ws_kill(){
    [ -z "$1" ] && exit 1 || kill "$(cat "$MASH_STATUS_DIR/proc/shard_$1")"
}

dispatch(){
    eval "MASH_DISPATCH_$1='$2'"
    export "MASH_DISPATCH_$1"
}

ewait(){
    [ -z "$1" ] && exit 1
    PIPE="$MASH_STATUS_DIR/wait/${3:-@}/$(uuidgen)"
    rm -f "$PIPE"
    mkfifo "$PIPE"
    tail -f > "$PIPE" &
    trap "kill -9 $! 2> /dev/null; rm -f '$PIPE'" EXIT

    QUERY="fromstream(0|truncate_stream(inputs)) | select($1)"
    timeout "${2:-0}" cat "$PIPE" \
    | jq -cM --stream --unbuffered "$QUERY" \
    | while IFS= read -r EVENT || [ -n "$EVENT" ]; do
        printf '%s\n' "$EVENT"
        exit
    done
}
