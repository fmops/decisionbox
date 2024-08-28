import os

import asyncio
import aiohttp

EXBOX_URL = "http://localhost:4000/api/decision_sites/1/invoke"

async def main():
    async with aiohttp.ClientSession() as session:
        async with session.post(EXBOX_URL, json={
            "messages": [
                {
                    "role": "user",
                    "content": "This is a test: I need vitamin C. Should I eat pears?",
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
            print(await resp.text())

asyncio.run(main())
