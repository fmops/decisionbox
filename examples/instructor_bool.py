from openai import OpenAI
from instructor import from_openai, Mode
from pydantic import BaseModel

client = from_openai(OpenAI(), mode=Mode.TOOLS_STRICT)


class Decision(BaseModel):
    value: bool

resp = client.chat.completions.create(
    response_model=Decision,
    messages=[
        {
            "role": "user",
            "content": "I need vitamin C. Should I eat pears?",
        }
    ],
    model="gpt-4o",
)
print(resp)
