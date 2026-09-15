import urllib.request
import json
import random

url = "https://momento-api-6-xc1u.onrender.com/api/auth/register"

unique_email = f"amit_test_{random.randint(10000, 99999)}@gmail.com"
unique_username = f"amit_{random.randint(10000, 99999)}"

payloads = [
    {
        "name": "Amit Kumar",
        "username": unique_username,
        "email": unique_email,
        "password": "password123",
        "profileimage": "https://www.gravatar.com/avatar/"
    },
    {
        "full_name": "Amit Kumar",
        "username": unique_username + "2",
        "email": f"2_{unique_email}",
        "password": "password123",
        "profileimage": "https://www.gravatar.com/avatar/"
    },
    {
        "name": "Amit Kumar",
        "username": unique_username + "3",
        "email": f"3_{unique_email}",
        "password": "password123"
    },
    {
        "full_name": "Amit Kumar",
        "username": unique_username + "4",
        "email": f"4_{unique_email}",
        "password": "password123"
    }
]

for i, p in enumerate(payloads):
    req = urllib.request.Request(url, data=json.dumps(p).encode('utf-8'), headers={'Content-Type': 'application/json'})
    try:
        with urllib.request.urlopen(req) as resp:
            print(f"Test {i} status: {resp.status}")
            print(f"Test {i} body: {resp.read().decode('utf-8')}")
    except urllib.error.HTTPError as e:
        print(f"Test {i} HTTPError: {e.code}")
        print(f"Test {i} Error body: {e.read().decode('utf-8')}")
    except Exception as e:
        print(f"Test {i} Error: {e}")
