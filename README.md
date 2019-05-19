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

## Environment
- `MASH_AUTH_TOKEN` - The token of the user
- `MASH_AUTH_BOT` - `1` for bot users, `0` for user bots
- `MASH_STATUS_DIR` - The directory where the scripts will save  
their pipes and statuses

