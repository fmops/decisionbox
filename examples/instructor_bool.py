from openai import OpenAI
from instructor import from_openai, Mode
from pydantic import BaseModel

client = from_openai(OpenAI(), mode=Mode.TOOLS_STRICT)


class Decision(BaseModel):
    value: bool

#
# resp = client.chat.completions.create(
#     response_model=Decision,
#     messages=[
#         {
#             "role": "user",
#             "content": "I need vitamin C. Should I eat pears?",
#         }
#     ],
#     model="gpt-4o",
# )
# print(resp)

# TODO: call excision
import asyncio
import aiohttp

EXBOX_URL = "http://localhost:4000/api/decision_sites/1/invoke"

async def main():
    async with aiohttp.ClientSession() as session:
        async with session.post(EXBOX_URL, json={
            "messages": [
                {
                    "role": "user",
                    "content": "I need vitamin C. Should I eat pears?",
                }
            ],
            "model": "gpt-4o-mini",
            "response_format": {
                "type": "json_schema",
                "json_schema": {
                    "name": "decision",
                    "schema": {
                        "type": "boolean"
                    }
                }
            }
        }) as resp:
            print(resp)
            #print(await resp.text())

asyncio.run(main())
