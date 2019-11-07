#!/bin/bash

set-args(){
    ARGS=( $@ )
    JSON=''
    for ARG in "${ARGS[@]}"; do
        IFS=':' read -ra ARGSQ <<< "$ARG"
        KEY="${ARGSQ[0]}" VAR=${ARGSQ[1]:-${ARGSQ[0]}}
        [ -n "${ARGSQ[2]}" ] && VALUE="${!VAR:-null}" || VALUE="\"${!VAR}\""
        JSON="$JSON\"$KEY\":$VALUE,"
    done
    JSON="{${JSON::-1}}"
    printf '%s\n' "$JSON"
}

get-args(){
    read -r JSON
    local ARGS=( $@ )
    local RQ=''
    local Q=''

    for ARG in "${ARGS[@]}"; do
        IFS=':' read -ra ARGSQ <<< "$ARG"
        local KEY="${ARGSQ[0]}"
        [ -n "${ARGSQ[2]}" ] && RQ="$RQ.$KEY," || Q="$Q.$KEY,"
    done

    if [ -n "$RQ" ]; then
        RQ="${RQ::-1}"
        RQ="$(printf '%s\n' "$JSON" | jq "$RQ")"
        mapfile -t RQ <<< "$RQ"
    fi

    if [ -n "$Q" ]; then
        Q="${Q::-1}"
        Q="$(printf '%s\n' "$JSON" | jq -r "$Q")"
        mapfile -t Q <<< "$Q"
    fi

    for ARG in "${ARGS[@]}"; do
        IFS=':' read -ra ARGSQ <<< "$ARG"
        VAR="${ARGSQ[1]:-${ARGSQ[0]}}"

        if [ -n "${ARGSQ[2]}" ]; then
            VALUE="${RQ[0]}"
            RQ="${RQ[@]:1}"
        else
            VALUE="${Q[0]}"
            Q="${Q[@]:1}"
        fi

        printf '%s=%s\n' "$VAR" "'$VALUE'"
    done
}

format-args(){
    read -r PAYLOAD
    case "$1" in
    'json')
        [ -n "$3" ] && EXTRA=",($3)"
        printf '%s\n' "$PAYLOAD" \
        | jq -cMr "({$2} | with_entries(select(.value!=null)))$EXTRA" ;;
    'url')
        local URL_CODE="({$2} | with_entries(select(.value!=null))"
        local URL_CODE="$URL_CODE | keys[] as \$k | \"\(\$k)=\(.[\$k])&\")"
        local URL="$(printf '%s\n' "$PAYLOAD" | jq -jr "$URL_CODE")"

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

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    cat ../usage/utils >&2
    exit 1
fi
