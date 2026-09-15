import urllib.request
import json
import random

base_url = "https://momento-api-17.onrender.com"

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
            res_body = resp.read().decode('utf-8')
            print(f"Response: {res_body}")
            return json.loads(res_body)
    except urllib.error.HTTPError as e:
        res_body = e.read().decode('utf-8')
        print(f"{method} {path} -> Error {e.code}: {res_body}")
        try:
            return json.loads(res_body)
        except:
            return None
    except Exception as e:
        print(f"{method} {path} -> Exception: {e}")
        return None

print("--- Testing API v17 ---")
# 1. Login or Register to get a token
uid = random.randint(1000, 9999)
email = f"test_{uid}@gmail.com"
reg_body = {
    "username": f"user_{uid}",
    "email": email,
    "password": "Password123",
    "full_name": "Test User"
}
reg_resp = test_endpoint("/api/auth/register", method='POST', body=reg_body)

token = None
if reg_resp and reg_resp.get('success'):
    token = reg_resp['data'].get('token')
    user_id = reg_resp['data']['user'].get('id') or reg_resp['data']['user'].get('uid')
    print(f"User ID: {user_id}")
else:
    print("Registration failed, trying login...")
    login_resp = test_endpoint("/api/auth/login", method='POST', body={"email": email, "password": "Password123"})
    if login_resp and login_resp.get('success'):
        token = login_resp['data'].get('token')
        user_id = login_resp['data']['user'].get('id') or login_resp['data']['user'].get('uid')

if token:
    # 2. Check feed
    print("\n--- Checking Feed ---")
    test_endpoint("/api/posts?page=1", token=token)
    
    # 3. Check profile posts
    print("\n--- Checking User Posts ---")
    test_endpoint(f"/api/posts/user/{user_id}", token=token)
    
    # 4. Try creating a post (using JSON as proxy for multipart check)
    print("\n--- Trying Create Post ---")
    test_endpoint("/api/posts", method='POST', body={"caption": "Hello world", "mediaType": "image"}, token=token)
else:
    print("Could not obtain auth token.")
