import os
import asyncio
import tempfile
import textwrap
import traceback
import subprocess

def PATCH(client):
    ENV = os.environ
    
    @client.event
    async def on_message(message):
        # Returns the command that will be used as the shell
        async def GET_SHELL(message):
            return '/bin/bash'

        # Returns the command in the message
        # This can be used to set a command prefix, permissions, etc
        async def GET_COMMAND(message):
            if message.author.id == int(ENV['MASH_OWNER']):
                msg = message.content.lstrip()
                return msg[1:] if msg[0] == '$' else None

        # Update the environment of the subprocess with
        # useful variables
        async def UPDATE_ENV(env, message):
            env['PATH'] = f'{ENV["MASH_SCRIPTS"]}:{ENV["PATH"]}'
            if message.guild is not None:
                env['CONTEXT_GUILD'] = str(message.guild.id)
            else:
                env['CONTEXT_GUILD'] = '0'
            env['CONTEXT_CHANNEL'] = str(message.channel.id)
            env['CONTEXT_AUTHOR'] = str(message.author.id)
            env['CONTEXT_ID'] = str(message.id)
            env['CONTEXT_CONTENT'] = message.content
            env['MASH_SCRIPTS'] = ENV['MASH_SCRIPTS']
            env['MASH_OWNER'] = ENV['MASH_OWNER']

        shell = await GET_SHELL(message)
        command = await GET_COMMAND(message)
        if command is not None:
            await message.add_reaction('🐍')
            env = ENV.copy() 
            await UPDATE_ENV(env, message)
            proc = await asyncio.create_subprocess_exec(shell, env=env, stdin=subprocess.PIPE, 
                                                        stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            result = await proc.communicate(command.encode())
            markdown = ENV.get('MASH_MARKDOWN', 'sh')
            if result[0]:
                await message.channel.send(f'```{markdown}\n{result[0].decode()}```')
            if result[1]: 
                await message.channel.send(f'```{markdown}\n{result[1].decode()}```')

    @client.event
    async def on_ready():
        print(client.user.name)
        print(client.user.id)
