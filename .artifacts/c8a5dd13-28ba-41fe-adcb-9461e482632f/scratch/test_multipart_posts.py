import urllib.request
import json

# Login
url_login = 'https://momento-api-22.onrender.com/api/auth/login'
req = urllib.request.Request(url_login, data=json.dumps({'email': 'test_60571@gmail.com', 'password': 'password123'}).encode('utf-8'), headers={'Content-Type': 'application/json'})
with urllib.request.urlopen(req) as resp:
    token = json.loads(resp.read().decode('utf-8'))['data']['token']

url_posts = 'https://momento-api-22.onrender.com/api/posts'

boundary = '---------------------------1234567890'
headers = {
    'Content-Type': f'multipart/form-data; boundary={boundary}',
    'Authorization': f'Bearer {token}'
}

def test_multipart(file_field, media_type_field):
    body = bytearray()
    body.extend(f'--{boundary}\r\nContent-Disposition: form-data; name="caption"\r\n\r\nTest caption\r\n'.encode('utf-8'))
    body.extend(f'--{boundary}\r\nContent-Disposition: form-data; name="{media_type_field}"\r\n\r\nimage\r\n'.encode('utf-8'))
    body.extend(f'--{boundary}\r\nContent-Disposition: form-data; name="{file_field}"; filename="test.png"\r\nContent-Type: image/png\r\n\r\n'.encode('utf-8'))
    body.extend(b'\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1f\x15c4\x00\x00\x00\rIDATx\x9cc`\x00\x00\x00\x02\x00\x01H\xaf\xa4q\x00\x00\x00\x00IEND\xaeB`\x82\r\n')
    body.extend(f'--{boundary}--\r\n'.encode('utf-8'))
    
    req = urllib.request.Request(url_posts, data=bytes(body), headers=headers)
    try:
        with urllib.request.urlopen(req) as resp:
            print(f'SUCCESS ({file_field}, {media_type_field}): {resp.status} {resp.read().decode("utf-8")}')
    except urllib.error.HTTPError as e:
        print(f'HTTPError ({file_field}, {media_type_field}): {e.code} {e.read().decode("utf-8")[:300]}')

print('--- Testing file field names ---')
for field in ['media', 'file', 'image', 'post', 'profileimage']:
    test_multipart(field, 'mediaType')
