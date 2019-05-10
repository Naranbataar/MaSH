# MaSH - A minimalistic and highly customizable Shell-based Discord Bot
MaSh is an advanced customizable bot that interacts as a shell

## Features
- Unbloated, stable and minimalistic
- Very extensible and customizable
- Commands can be writen as shell script
- GNU-inspired scripts and commands [TODO]
- Shell-like command line

## Requirements
- Python 3.6+
- `discord.py` library [rewrite] (until the bot have its own websocket logic)

## Default Environment

### Required Variables
- `MASH_CONFIG` - The path for the config file
- `MASH_TOKEN` - The token of the bot user
- `MASH_BOT` - If 0, it will connect as a self-bot, else, it will connect as a bot user

### (Default Config) Required Variables
- `MASH_TASKS` - The folder that will act as a shared memory for scripts that access the bot variables, 
its recommended to be a secure folder (to prevent shell injection), inside a ram disk (to speed up the files)
- `MASH_SCRIPTS` - The folder that the default scripts are in, needs to be an absolute path, 
usually is defined by `$(realpath scripts)`
- `MASH_OWNER` - Required if `GET_COMMAND` inside `on_message` is unchanged, the id of the owner of the bot

### (Default Config) Optional Variables
- `MASH_MARKDOWN` - The highlight.js markdown that will be used on the codeblocks, defaults to "sh"

## Customization

The default `config.py` script contains all the bot logic, its source can be modified to change the bot behaviour  
- `PATCH` - Called by the start script to make modifications on `client` variable
    - `on_ready` - A client event, prints just a the username and id
    - `on_message` - A client event, holds the most part of this bot logic, it can be customized completly or by its helper functions:
        - `GET_SHELL` - Accepts a message, and returns a string that is the path of the shell, can be used to set a different shell for each context
        - `GET_COMMAND` - Accepts a message, defines if the bot will respond, and remove any prefixes of the message, can be used to set custom calls and command manipulation before the execution
        - `UPDATE_ENV` - Accepts a env and a message, set some useful variables for the shell
    - `python_script_listener` - A client listener, watches the `$MASH_TASKS` folder for .in files containing python script, runs and outputs them as .out and .err
    
## F.A.Q

### The bot only answers to the owner
It's the default behaviour for security purposes, you can change that on `GET_COMMAND` function

### But if i change it, people will have access to my system
You can change the shell to a protected one for specific users or context on `GET_SHELL`

### How can i change the prefix?
The prefix is defined on the`GET_COMMAND` function
