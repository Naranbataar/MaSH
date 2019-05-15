# MaSH - A minimalistic Discord toolset made in Bash
MaSh is a set of scripts made in Bash to make possible to  
write Discord Bots on pure Shell Script

## Features
- Unbloated, stable and minimalistic
- Follows the Unix Philosophy
- Universal, scripts can interact with it using the  
standart input/output

## Requirements
- `curl`
- `jq`
- `websocat`
- `expect`

## Default Environment

- `MASH_CONFIG` - The path for the config file
- `MASH_TOKEN` - The token of the bot user
- `MASH_BOT` - If 0, it will connect as a self-bot, else, it will connect as a bot user
- `MASH_USERAGENT` - The user-agent to connect to discord servers
