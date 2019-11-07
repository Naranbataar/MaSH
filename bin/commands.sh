#!/bin/bash

prefix(){
    MASH_PREFIX=( $1 )
    export "MASH_PREFIX"
}

xcommand(){
    [ "$(type -t "$1")" == "function" ] && export -f "$1"
    NAMES=( $2 )
    for NAME in "${NAMES[@]}"; do
        eval "MASH_COMMAND_$NAME='$1'"
        export "MASH_COMMAND_$NAME"
        eval "MASH_COMMAND_${NAME}_CTX='$3'"
        export "MASH_COMMAND_${NAME}_CTX"
    done
}

_parse-commands(){
    CONTENT="$(printf '%s\n' "$1" | grep -oP '(?<="content":").*?(?=",)')"
    if [ -n "$MASH_PREFIX" ]; then
        for TEST_PREFIX in "${MASH_PREFIX[@]}"; do
            if [[ "$CONTENT" == "$TEST_PREFIX"* ]]; then
                PREFIX="$TEST_PREFIX"; break
            fi
        done
    else
        exit
    fi
    [ -z "$PREFIX" ] && exit

    BOT=$(printf '%s\n' "$1" | jq '.author|.bot')
    [ "$BOT" == "true" ] && exit

    CONTENT=${CONTENT#$PREFIX}

    CONTENT=("${CONTENT[@]//\\\"/\"}")
    CONTENT=$(xargs printf '%s\n' <<< "$CONTENT")

    mapfile -t ARGS <<< "$CONTENT"
    ARGS=("${ARGS[@]//\"/\\\"}")

    COMMAND="${ARGS[0]}"
    FUNC="MASH_COMMAND_$COMMAND"
    FUNC="${!FUNC}"
    [ -z "$FUNC" ] && exit

    CTXSTR="MASH_COMMAND_${COMMAND}_CTX"
    CTXSTR="${!CTXSTR}"
    CTX="$(printf '%s\n' "$1" | jq -r "$CTXSTR")"

    export CTX
    "$FUNC" "${ARGS[@]:1}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    cat ../usage/commands >&2
    exit 1
else
    source websocket.sh
    dispatch MESSAGE_CREATE _parse-commands
fi
