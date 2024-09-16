import json
import os

import asyncio
import aiohttp

EXBOX_URL = "https://decisionbox.blueteam.ai/api/decision_sites/5/invoke"

async def main():
    async with aiohttp.ClientSession() as session:
        async with session.post(EXBOX_URL, json={
            "messages": [
                {
                    "role": "user",
                    "content": "Random choice: nice or bad?",
                }
            ],
            "model": "gpt-4o-mini",
            # TODO: currently this is assumed by backend, allow users to specify response format
            # "response_format": {
            #     "type": "json_schema",
            #     "json_schema": {
            #         "name": "Decision",
            #         "schema": {
            #             "type": "object",
            #             "properties": {
            #                 "value": {
            #                     "type": "boolean"
            #                 }
            #             },
            #         }
            #     }
            # }
        }, headers={ 'Authorization': f"Bearer {os.environ.get('OPENAI_API_KEY')}" }) as resp:
            print(resp)
            print(json.loads((await resp.json())['choices'][0]['message']['content'])['value'])

asyncio.run(main())
