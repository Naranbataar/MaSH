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

## Example (with commands)

```bash
#!/bin/bash
PATH="$PATH:$(realpath ./mash/bin)"
source commands

MASH_AUTH_TOKEN='TOKEN'; export MASH_AUTH_TOKEN
MASH_AUTH_BOT=1; export MASH_AUTH_BOT

prefix '> ! ? mash'

on-ready(){ echo -e "$(echo "$1" | jq -r '.user | .username,.id')"; }
on-resume(){ echo "Resumed"; }

dispatch READY on-ready
dispatch RESUMED on-resume

speak(){
	content="<@${CTX[0]}> wants me to say: '$@'"
	channel="${CTX[1]}"
	result="$(set-args content channel | message send)"

	eval "$(echo "$result" | get-args id)"
	echo "$id"
}

xcommand speak 'say speak tell' '(.author|.id),.channel_id'

bot-loop
```

## Example (without commands)
```bash
#!/bin/bash
PATH="$PATH:$(realpath ./mash/bin)"

MASH_AUTH_TOKEN='TOKEN'; export MASH_AUTH_TOKEN
MASH_AUTH_BOT=1; export MASH_AUTH_BOT

on-ready(){ echo -e "$(echo "$1" | jq -r '.user | .username,.id')"; }
on-resume(){ echo "Resumed"; }

on-message(){
	prefix=">"
	context=$(echo "$1"| jq -r '.id,(.author|.id),.channel_id,.guild_id,(.author|.bot)')
	mapfile -t context <<< "$context"

	message=${context[0]}; author=${context[1]}; channel=${context[2]}
	guild=${context[3]}; bot=${context[4]}

	content=$(echo "$1" | jq '.content')
	content=${content#'"'}; content=${content%'"'}

	[[ "$content" != "$prefix"* ]] && exit
	[ "$bot" == "true" ] && exit

	content=${content#$prefix}
	IFS=' ' read -r -a args <<< "$content"

	case ${args[0]} in
	'hi') echo "{\"channel\": \"$channel\", \"content\": \"hello\"}" | message send >> /dev/null;;
	esac
}

JOBS=($(jobs -p))
while read -r EVENT; do
	while (( ${#JOBS[*]} >= 100 )); do
		sleep 0.5; JOBS=($(jobs -p))
	done

	T=$(echo "$EVENT" | jq -r '.t')
	D=$(echo "$EVENT" | jq -cM '.d')
	case $T in
	'READY') on-ready "$D" & ;;
	'RESUMED') on-resume "$D" & ;;
	'MESSAGE_CREATE') on-message "$D" & ;;
	esac
done < <(ws-start)
```

## Environment
- `MASH_AUTH_TOKEN` - The token of the user
- `MASH_AUTH_BOT` - `1` for bot users, `0` for user bots
- `MASH_STATUS_DIR` - The directory where the scripts will save
their pipes and statuses

## Todo
- Voice Support
