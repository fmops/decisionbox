import json
import os

import requests

url = 'http://localhost:4000/api/decision_sites/9/invoke'
headers = {'Authorization': f'Bearer {os.environ.get("OPENAI_API_KEY")}'}
data = {
  "messages": [
    {
      "role": "user",
      "content": "Is this transaction fraudulent? user_age=30, purchase=car"
    }
  ],
  "model": "gpt-4o-mini",
  "response_format": {
    "type": "json_schema",
    "json_schema": {
      "name": "Decision",
      "schema": {
        "type": "object",
        "properties": {
          "value": {
            "enum": ["true", "false"]
          }
        },
      }
    }
  }
}

response = requests.post(url, json=data, headers=headers)

if response.status_code == 200:
    decision = json.loads((response.json())['choices'][0]['message']['content'])['value']
    print(f"Decision: {decision}")
else:
    print(f"Error: {response.status_code}")
