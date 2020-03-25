set_args(){
    if [ "$#" -lt 1 ]; then
        printf '%s\n' 'usage: set_args ARG1 [ARG2] ... [ARGN]' >&2
        printf '%s\n' 'Creates a json object' >&2
        printf '\n' >&2
        printf '%s\n' 'ARGS: KEY:[VAR]:[RAW]' >&2
        printf '%s\n' '    KEY: A json key' >&2
        printf '%s\n' '    VAR: A var holding the data, KEY if empty' >&2
        printf '%s\n' '    RAW: Empty for string, @ for raw json' >&2
        return 1
    fi

    json=''
    for arg in "$@"; do
        IFS=':' read -r key var raw <<EOF
$arg
EOF
        var="${var:-$key}"
        var="$(eval "printf '%s\\n' \"\${$var}\"")"
        if [ -n "$raw" ]; then 
            value="${var:-null}"
        else
            escapes='s//\\r/g; s//\\f/g; s//\\b/g; s/	/\\t/g'
            escapes2='s/\\/\\\\/g; s/"/\\"/g'
            var="$(printf '%s\n' "$var" \
                   | sed "$escapes; $escapes2" \
                   | awk 1 ORS='\\n')"
            value="\"$var\""
        fi
        json="${json}\"${key}\":$value,"
    done
    printf '%s\n' "{${json%?}}"
}

# shellcheck disable=SC2016
get_args(){
    if [ "$#" -lt 1 ]; then
        printf '%s\n' 'usage: get_args ARG1 [ARG2] ... [ARGN]' >&2
        printf '%s\n' 'Retrives data from a json object' >&2
        printf '\n' >&2
        printf '%s\n' 'ARGS: KEY:[VAR]:[RAW]' >&2
        printf '%s\n' '    KEY: A json key' >&2
        printf '%s\n' '    VAR: A var to hold the data, KEY if empty' >&2
        printf '%s\n' '    RAW: Empty for string, @ for raw json' >&2
        return 1
    fi

    read -r json
    rq=''; q=''

    for arg in "$@"; do
        IFS=':' read -r key var raw <<EOF
$arg
EOF
        [ -n "$raw" ] && rq="$rq.$key," || q="$q.$key,"
    done

    [ -n "$rq" ] && rq="$(printf '%s\n' "$json" | jq -cM "${rq%?}")"
    [ -n "$q" ] && q="$(printf '%s\n' "$json" | jq -cMr "${q%?}")"

    rqn=1; qn=1
    for arg in "$@"; do
        IFS=':' read -r key var raw <<EOF
$arg
EOF
        var="${var:-$key}"

        if [ -n "$raw" ]; then
            value="$(printf '%s\n' "$rq" | sed -n "${rqn}p")"
            rqn="$(( rqn + 1 ))"
        else
            value="$(printf '%s\n' "$q" | sed -n "${qn}p")"
            qn="$(( qn + 1 ))"
        fi

        tmp=$(mktemp)
        printf '%s\n' "$value" > "$tmp" 
        printf '%s="$(cat "%s"; rm "%s")"\n' "$var" "$tmp" "$tmp"
    done
}

urify(){
    if [ "$#" -lt 1 ]; then
        printf '%s\n' 'usage: urify KEY' >&2
        printf '%s\n' 'Converts a file to URI string inside a json object' >&2
        printf '%s\n' 'Accepts a JSON string on STDIN' >&2
        printf '\n' >&2
        printf '%s\n' 'KEY: The key with the path' >&2
        return 1
    fi

    read -r text
    image="$(printf '%s\n' "$text" | jq -r ".$1")"
    mime="$(file -bN --mime-type "$image")"
    printf '%s\n' "data:$mime;base64,$(base64 -w 0 "$image")" > "$image.b64"
    text="$(printf '%s\n' "$text" \
            | jq --rawfile img "$image.b64" ".$1 = \$img")"
    rm "$image.b64"
    printf '%s\n' "$text"
}
