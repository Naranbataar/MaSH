#!/bin/sh

set_args(){
    json=''
    for arg in "$@"; do
        IFS=':' read -r key var raw <<-EOF
		$arg
		EOF
        var="${var:-$key}"
        var="$(eval "echo \${$var}")"
        [ -n "$raw" ] && value="${var:-null}" || value="\"$var\""
        json="${json}\"${key}\":$value,"
    done
    printf '%s\n' "{${json%?}}"
}

#this posix version may be slower, measure it
get_args(){
    read -r json
    raw_query=''; str_query=''

    for arg in "$@"; do
        IFS=':' read -r key var raw <<-EOF
		$arg
		EOF
        [ -n "$raw" ] && raw_query="$raw_query.$key," \
                      || str_query="$str_query.$key,"
    done

    [ -n "$raw_query" ] && raw_query="$(printf '%s\n' "$json" \
                                        | jq "${raw_query%?}")"
    [ -n "$str_query" ] && str_query="$(printf '%s\n' "$json" \
                                        | jq -r "${str_query%?}")"

    raw_n=0; str_n=0
    for arg in "$@"; do
        IFS=':' read -r key var raw <<-EOF
		$arg
		EOF
        var="${var:-$key}"

        if [ -n "$raw" ]; then
            value="$(printf "$raw_query" | sed -n "${raw_n}p")"
            raw_n="$(( raw_n + 1 ))"
        else
            value="$(printf "$str_query" | sed -n "${str_n}p")"
            str_n="$(( str_n + 1 ))"
        fi

        printf '%s=%s\n' "$var" "'$value'"
    done
}

format_args(){
    read -r payload
    case "$1" in
    'json')
        [ -n "$3" ] && extra=",($3)"
        printf '%s\n' "$payload" \
        | jq -cMr "({$2} | with_entries(select(.value!=null)))$extra" ;;
    'url')
        url_code="({$2} | with_entries(select(.value!=null))"
        url_code="$url_code | keys[] as \$k | \"\(\$k)=\(.[\$k])&\")"
        url="$(printf '%s\n' "$payload" | jq -jr "$url_code")"

        if [ -n "$url" ]; then
            printf '?%s\n' "${url%?}"
        else
            printf "\n"
        fi

        if [ -n "$3" ]; then
            printf '%s\n' "$(printf '%s\n' "$payload" | jq -r "$3")"
        fi ;;
    esac
}

urify(){
    read -r text
    image="$(printf '%s\n' "$text" | jq -r ".$1")"
    mime="$(file -bN --mime-type "$image")"
    printf '%s\n' "data:$mime;base64,$(base64 -w 0 "$image")" > "$image.b64"
    text="$(printf '%s\n' "$text" \
            | jq --rawfile img "$image.b64" ".$1 = \$img")"
    rm "$image.b64"
    printf '%s\n' "$text"
}
