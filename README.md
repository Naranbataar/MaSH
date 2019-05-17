# MaSH - A minimalistic Discord toolset made in Bash
MaSh is a set of scripts made in Bash to make possible to  
write Discord Bots on pure Shell Script

## Features
- Unbloated, stable and minimalistic
- Follows the Unix Philosophy
- Universal, scripts can interact with it using the  
standart input/output

## Requirements
- `jq`
- `curl`
- `websocat`

## Default Environment
- `MASH_WS_PID` - The pid of the running websocket
- `MASH_WS_PIPE` - The command pipe of the running websocket
- `MASH_HTTP_AUTH` - The Authorization header, `Bot TOKEN` for bot users, `TOKEN` for user bots
- `MASH_HTTP_USERAGENT` - The User-Agent header

