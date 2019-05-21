# MaSH - A minimalistic Discord toolset made in Bash
MaSh is a set of scripts made in Bash to make possible to  
write Discord Bots on pure Shell Script

## Features
- Unbloated, stable and minimalistic
- Follows the Unix Philosophy
- Universal, scripts of any language can   
interact using the standart input/output
- Implements the entire Discord API
- Voice Support [TODO]

## Requirements
- `jq`
- `curl`
- `websocat`

## Example

```bash
#!/bin/bash
PATH="$PATH:$(realpath ./mash/bin):$(realpath ./mash/extra)"

MASH_AUTH_TOKEN='TOKEN'; export MASH_AUTH_TOKEN
MASH_AUTH_BOT=0; export MASH_AUTH_BOT

while read -r EVENT; do
	jwait $$ 100
	prefix=">";
	T=$(echo "$EVENT" | jq -r '.t')
	D=$(echo "$EVENT" | jq -r '.d')
	if [ "$T" == "MESSAGE_CREATE" ]; then
		content=$(echo "$D" | jq -r '.content')
		channel=$(echo "$D" | jq -r '.channel_id')
		author=$(echo "$D" | jq '.author' | jq -r '.id')
		[ "$author" == "580420373410086932" ] && continue

		content=${content#$prefix}
		IFS=' ' read -r -a args <<< "$content"

		case ${args[0]} in
		'hi') message send "{\"channel\": \"$channel\", \"content\": \"hello\"}";;
		esac
		
	fi
done < <(ws-connect)
```

## Environment
- `MASH_AUTH_TOKEN` - The token of the user
- `MASH_AUTH_BOT` - `1` for bot users, `0` for user bots
- `MASH_STATUS_DIR` - The directory where the scripts will save  
their pipes and statuses
