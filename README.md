# MaSH - A minimalistic Discord toolset made in Bash
MaSh is a set of scripts made in Bash to make possible to  
write Discord Bots on pure Shell Script

## Features
- Unbloated, stable and minimalistic
- Follows the Unix Philosophy
- Universal, scripts of any language can   
interact using the standart input/output

## Requirements
- `jq`
- `curl`
- `websocat`

## Default Environment
- `MASH_AUTH_TOKEN` - The token of the user
- `MASH_AUTH_BOT` - `1` for bot users, `0` for user bots
- `MASH_HTTP_USERAGENT` - The User-Agent header
- `MASH_WS_PID` - The pid of the running websocket
- `MASH_WS_PIPE` - The command pipe of the running websocket

