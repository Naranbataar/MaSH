#!/bin/sh

set_args(){
    JSON=''
    for ARG in "$@"; do
        IFS=':' read -r KEY VAR RAW <<-EOF
		$ARG
		EOF
        echo "$KEY $VAR $RAW"
        VAR="${VAR:-$KEY}"
        VAR="$(eval "echo \${$VAR}")"
        [ -n "$RAW" ] && VALUE="${VAR:-null}" || VALUE="\"$VAR\""
        JSON="${JSON}\"${KEY}\":$VALUE,"
    done
    printf '%s\n' "{${JSON%?}}"
}

#this posix version may be slower, measure it
get_args(){
    read -r JSON
    RQ=''; Q=''

    for ARG in "$@"; do
        IFS=':' read -r KEY VAR RAW <<-EOF
		$ARG
		EOF
        [ -n "$RAW" ] && RQ="$RQ.$KEY," || Q="$Q.$KEY,"
    done

    [ -n "$RQ" ] && RQ="$(printf '%s\n' "$JSON" | jq "${RQ%?}")"
    [ -n "$Q" ] && Q="$(printf '%s\n' "$JSON" | jq -r "${Q%?}")"

    RQN=0; QN=0
    for ARG in "$@"; do
        IFS=':' read -r KEY VAR RAW <<-EOF
		$ARG
		EOF
        VAR="${VAR:-$KEY}"

        if [ -n "$RAW" ]; then
            VALUE="$(printf "$RQ" | sed -n "${RQN}p")"
            RQN="$(( RQN + 1 ))"
        else
            VALUE="$(printf "$Q" | sed -n "${QN}p")"
            QN="$(( QN + 1 ))"
        fi

        printf '%s=%s\n' "$VAR" "'$VALUE'"
    done
}

format_args(){
    read -r PAYLOAD
    case "$1" in
    'json')
        [ -n "$3" ] && EXTRA=",($3)"
        printf '%s\n' "$PAYLOAD" \
        | jq -cMr "({$2} | with_entries(select(.value!=null)))$EXTRA" ;;
    'url')
        URL_CODE="({$2} | with_entries(select(.value!=null))"
        URL_CODE="$URL_CODE | keys[] as \$k | \"\(\$k)=\(.[\$k])&\")"
        URL="$(printf '%s\n' "$PAYLOAD" | jq -jr "$URL_CODE")"

        if [ -n "$URL" ]; then
            printf '?%s\n' "${URL%?}"
        else
            printf "\n"
        fi

        if [ -n "$3" ]; then
            printf '%s\n' "$(printf '%s\n' "$PAYLOAD" | jq -r "$3")"
        fi ;;
    esac
}

urify(){
    read -r TEXT
    IMAGE="$(printf '%s\n' "$TEXT" | jq -r ".$1")"
    MIME="$(file -bN --mime-type "$IMAGE")"
    printf '%s\n' "data:$MIME;base64,$(base64 -w 0 "$IMAGE")" > "$IMAGE.b64"
    TEXT="$(printf '%s\n' "$TEXT" \
            | jq --rawfile img "$IMAGE.b64" ".$1 = \$img")"
    rm "$IMAGE.b64"
    printf '%s\n' "$TEXT"
}
