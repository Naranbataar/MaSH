import os
import asyncio
import discord
import tempfile
import textwrap
import traceback

import config

ENV = os.environ
client = discord.Client()

@client.event
async def on_message(message):
   return await config.ON_MESSAGE(message)

@client.event
async def on_ready():
    print(client.user.name)
    print(client.user.id)

async def executor(task):
    env = {**globals(), **locals()}
    code = open(task).read()
    code = textwrap.indent(code, ' '*4)
    code = f'async def _task(client):\n{code}'
    task = task.rsplit('.', 1)[0]
    try:
        exec(code, env)
        result = await env['_task'](client)
        result = str(result) if result is not None else ''
        open(f'{task}.out', 'w').write(result)
    except:
        open(f'{task}.err', 'w').write(traceback.format_exc())

async def listener():
    files = []
    folder = ENV['MASH_TASKS']
    while True:
        new = [x for x in os.listdir(folder) if x.endswith('.in')]
        for x in new:
            if x not in files:
                x = os.path.join(folder, x)
                client.loop.create_task(executor(x))
        files = new
        await asyncio.sleep(0.1)

client.loop.create_task(listener())

token = ENV['MASH_TOKEN']
bot = bool(int(ENV['MASH_BOT']))
client.run(token, bot=bot)
