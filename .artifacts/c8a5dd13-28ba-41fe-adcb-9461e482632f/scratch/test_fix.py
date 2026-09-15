import urllib.request
import json
import random

url = "https://momento-api-6-xc1u.onrender.com/api/auth/register"

uid = random.randint(100000, 999999)
payload = {
    "name": "Amit Kumar",
    "full_name": "Amit Kumar",
    "username": f"amit_{uid}",
    "email": f"amit_{uid}@gmail.com",
    "password": "password123",
    "profileimage": "https://www.gravatar.com/avatar/",
    "profile_image": "https://www.gravatar.com/avatar/"
}

req = urllib.request.Request(url, data=json.dumps(payload).encode('utf-8'), headers={'Content-Type': 'application/json'})
try:
    with urllib.request.urlopen(req) as resp:
        print("Status:", resp.status)
        print("Body:", resp.read().decode('utf-8'))
except urllib.error.HTTPError as e:
    print("HTTPError:", e.code)
    print("Error Body:", e.read().decode('utf-8'))
except Exception as e:
    print("Error:", e)
