# MaSH - A minimalistic Discord API wrapper compatible with Posix Shells
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
#!/bin/sh
PATH="$PATH:$(realpath ./MaSH/bin)"
. commands.sh
. websocket.sh

MASH_AUTH_TOKEN='TOKEN'
export MASH_AUTH_TOKEN
MASH_AUTH_BOT=1
export MASH_AUTH_BOT

prefix '> ! ? mash'

on_ready(){ printf "%s\n" "$1" | jq -r '.user | .username,.id' }
on_resume(){ printf "Resumed\n"; }

dispatch READY on_ready
dispatch RESUMED on_resume

xcommand 'commands/speak' 'say speak tell' '(.author|.id),.channel_id'

ws\_start
```
commands/speak
```bash
#!/bin/bash
. rest.sh
. utils.sh

IFS=':' read -r user channel <<-EOF
	"$ctx"
EOF

content="$user wants me to say: '$@'"
channel="$channel"
result="$(set_args content channel | message send)"

eval "$(echo "$result" | get_args id)"
echo "$id"
```

## Environment
- `MASH_AUTH_TOKEN` - The token of the user
- `MASH_AUTH_BOT` - `1` for bot users, `0` for user bots (Default `1`)
- `MASH_AUTH_GS` - Guild subscriptions, `1` for true, `0` for false (Default `0`)
- `MASH_STATUS_DIR` - The directory where the scripts will save
their pipes and statuses (Default `.mash_tmp`)
- `MASH_DISPATCH_*` - Shards will dispatch the events to functions that
environment variables with their respective names are referencing

## Todo
- Voice Support

