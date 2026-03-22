import os
import httpx

url = 'https://api.groq.com/openai/v1/chat/completions'
key = os.getenv('GROQ_API_KEY', '')
payload = {
    'model': 'llama-3.1-8b-instant',
    'messages': [
        {'role': 'system', 'content': 'Ban la tro ly, tra ve JSON.'},
        {'role': 'user', 'content': 'chi 40k an trua'}
    ],
    'response_format': {'type': 'json_object'}
}
headers = {
    'Authorization': f'Bearer {key}',
    'Content-Type': 'application/json'
}
resp = httpx.post(url, headers=headers, json=payload, timeout=30)
print('STATUS', resp.status_code)
print(resp.text[:1200])
