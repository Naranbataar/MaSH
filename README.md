# MaSH - A minimalistic Discord API wrapper compatible with Posix Shells
MaSH is a set of scripts for writing Discord Bots

## Features
- Follows the Unix Philosophy
- Modular and reliable
- Little to no abstraction
- Unbloated and minimalistic
- Universal, scripts/binaries of any language can  
interact using stdin/stdout
- Wraps the entire REST API
- Efficient rate limiting

## Requirements
- A POSIX environment
- `jq`
- `curl`
- `websocat`
- `flock` and `stdbuf` (already installed on most systems)

## Example
```sh
PATH="$PATH:$(realpath MaSH)"
. MaSH/extra/utils.sh

export MASH_TOKEN="TOKEN"
export MASH_BOT=true
export MASH_SHARD=0,1
export MASH_GS=true
export MASH_INTENTS=

run_command(){
    message="$1"
    content="$(echo "$message" | jq -r '.d|.content')"
    content="${content#>}"; name="${content%% *}"; args="${content#$name}"

    eval "$(printf '%s\n' "$message" | get_args d:data:@)"
    eval "$(printf '%s\n' "$data" | get_args channel_id)"

    if [ "$(basename "$name")" != '..' ] && [ -f "commands/$name" ]; then
        content="$(printf '%s\n' "$message" | "commands/$name" $args 2>&1)"
    else
        content="$name?"
    fi

    set_args channel:channel_id content | mash api message send > /dev/null
}

mash start &

while [ ! -d .mash ]; do sleep 1; done
mash listen \
       | jq --unbuffered -cM 'select((.op==0 and .t=="MESSAGE_CREATE")) |
                              select((.d|.content|startswith(">")))' \
       | while read -r message; do
             run_command "$message" &
         done
```

## Todo
- Replace `websocat` with a simpler tool
- Voice Support
