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

## Example

```bash
#!/bin/bash
PATH="$PATH:$(realpath ./mash/bin)"

MASH_AUTH_TOKEN='TOKEN'; export MASH_AUTH_TOKEN
MASH_AUTH_BOT=0; export MASH_AUTH_BOT

trap '$0 "$@"' SIGTERM

on-ready(){ echo -e "$(echo "$1" | jq -r '.user | .username,.id')"; }

on-message(){
	prefix=">";
	context=$(echo "$1"| jq -r '.content,.id,(.author|.id),.channel_id,.guild_id')
	mapfile -t context <<< "$context"
		
	content=${context[0]}; message=${context[1]}; author=${context[2]}
	channel=${context[3]}; guild=${context[4]};

	[[ "$content" != "$prefix"* ]] && exit
	[ "$author" == "580420373410086932" ] && exit

	content=${content#$prefix}
	IFS=' ' read -r -a args <<< "$content"

	case ${args[0]} in
	'hi') message send "{\"channel\": \"$channel\", \"content\": \"hello\"}" >> /dev/null;;
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
	'MESSAGE_CREATE') on-message "$D" & ;;
	esac
done < <(ws-connect)
```

## Environment
- `MASH_AUTH_TOKEN` - The token of the user
- `MASH_AUTH_BOT` - `1` for bot users, `0` for user bots
- `MASH_STATUS_DIR` - The directory where the scripts will save  
their pipes and statuses

## Todo
- Voice Support
- Reduce external calls
- Stability tests

