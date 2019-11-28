#!/bin/sh

prefix(){
    MASH_PREFIX="$(printf '%s\n' "$@" | xargs printf '%s\n')"
    export "MASH_PREFIX"
}

xcommand(){
    NAMES="$(printf '%s\n' "$2" | xargs printf '%s\n')"
    for NAME in "$NAMES"; do
        eval "MASH_COMMAND_${NAME}='$1'"
        export "MASH_COMMAND_${NAME}"
        eval "MASH_COMMAND_${NAME}_CTX='$3'"
        export "MASH_COMMAND_${NAME}_CTX"
    done
}

_parse_commands(){
    CONTENT="$(printf '%s\n' "$1" | grep -oP '(?<="content":").*?(?=",)')"
    if [ -n "$MASH_PREFIX" ]; then
        for TEST_PREFIX in "$MASH_PREFIX"; do
            case "$CONTENT" in "$TEST_PREFIX"*)
                PREFIX="$TEST_PREFIX"; break
            esac
        done
    else
        exit
    fi
    [ -z "$PREFIX" ] && exit

    BOT="$(printf '%s\n' "$1" | jq '.author|.bot')"
    [ "$BOT" = "true" ] && exit

    CONTENT="${CONTENT#$PREFIX}"
    CONTENT="$(printf "%s\n" "$CONTENT" | xargs printf '%s\n')"

    # Unsafe, someone can read the env using >key-:
    COMMAND="$(printf "%s\n" "$CONTENT" | head -n 1)"
    FUNC="MASH_COMMAND_$COMMAND"
    FUNC="$(eval "printf \${$FUNC}")"
    [ -z "$FUNC" ] && exit

    CTXSTR="MASH_COMMAND_${COMMAND}_CTX"
    CTXSTR="$(eval "printf \${$CTXSTR}")"
    CTX="$(printf '%s\n' "$1" | jq -r "$CTXSTR")"

    export CTX
    "$FUNC" "$(printf "%s\n" "$CONTENT" | tail -n +2)"
}

. websocket.sh
dispatch MESSAGE_CREATE _parse_commands
