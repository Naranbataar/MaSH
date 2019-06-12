# MaSH - A minimalistic Discord API wrapper made in Bash
MaSh is a set of scripts made in Bash to make possible to
write Discord Bots on pure Shell Script

## Features
- Unbloated and minimalistic
- Follows the Unix Philosophy
- Universal, scripts of any language can
interact using the standart input/output
- Wraps the entire REST API
- Efficient rate limiting

## Requirements
- `jq`
- `curl`
- `websocat`
- `parallel`

## Example
main
```bash
#!/bin/bash
PATH="$PATH:$(realpath ./mash/bin)"
source commands
source websocket

MASH_AUTH_TOKEN='TOKEN'; export MASH_AUTH_TOKEN
MASH_AUTH_BOT=1; export MASH_AUTH_BOT

prefix '> ! ? mash'

on-ready(){ echo -e "$(echo "$1" | jq -r '.user | .username,.id')"; }
on-resume(){ echo "Resumed"; }

dispatch READY on-ready
dispatch RESUMED on-resume

xcommand 'bin/speak' 'say speak tell' '(.author|.id),.channel_id'

ws-start
```
bin/speak
```bash
#!/bin/bash
source rest
source utils

content="<@${CTX[0]}> wants me to say: '$@'"
channel="${CTX[1]}"
result="$(set-args content channel | message send)"

eval "$(echo "$result" | get-args id)"
echo "$id"
```

## Environment
- `MASH_AUTH_TOKEN` - The token of the user
- `MASH_AUTH_BOT` - `1` for bot users, `0` for user bots
- `MASH_STATUS_DIR` - The directory where the scripts will save
their pipes and statuses
- `MASH_DISPATCH_*` - Shards will dispatch the events to functions that
environment variables with their respective names are referencing

## Todo
- Voice Support

