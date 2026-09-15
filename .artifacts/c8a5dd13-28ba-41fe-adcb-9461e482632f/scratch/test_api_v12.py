import urllib.request
import json
import random

base_url = "https://momento-api-12.onrender.com"

def test_endpoint(path, method='GET', body=None, token=None):
    url = f"{base_url}{path}"
    headers = {'Content-Type': 'application/json'}
    if token:
        headers['Authorization'] = f'Bearer {token}'
    
    data = json.dumps(body).encode('utf-8') if body else None
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    
    try:
        with urllib.request.urlopen(req) as resp:
            print(f"{method} {path} -> {resp.status}")
            return json.loads(resp.read().decode('utf-8'))
    except urllib.error.HTTPError as e:
        body = e.read().decode('utf-8')
        print(f"{method} {path} -> Error {e.code}: {body}")
        return None
    except Exception as e:
        print(f"{method} {path} -> Exception: {e}")
        return None

print("--- Testing API v12 ---")
health = test_endpoint("/health")

# Try to register a unique user to get a token
uid = random.randint(1000, 9999)
reg_body = {
    "username": f"tester_{uid}",
    "email": f"tester_{uid}@example.com",
    "password": "Password123",
    "full_name": "API Tester"
}
reg_resp = test_endpoint("/api/auth/register", method='POST', body=reg_body)

token = None
if reg_resp and reg_resp.get('success'):
    token = reg_resp['data'].get('token')
    print(f"Token obtained: {token[:10]}...")

if token:
    # Test posts
    print("\n--- Testing Posts ---")
    posts = test_endpoint("/api/posts", token=token)
    
    # Test user search
    print("\n--- Testing Search ---")
    search = test_endpoint("/api/users/search?q=tester", token=token)
    
    # Test create post (mock multipart by sending JSON if supported, or just check endpoint existence)
    # Note: Backend might require multipart, so this might fail with 400 or 500
    print("\n--- Testing Create Post (JSON) ---")
    create = test_endpoint("/api/posts", method='POST', body={"caption": "Test Post", "mediaType": "image"}, token=token)
else:
    print("Could not get token, skipping authenticated tests.")
