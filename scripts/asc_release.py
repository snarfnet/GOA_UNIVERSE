import os, time, base64, json
import jwt, requests

def api(path):
    token = jwt.encode({'iss': os.environ['APP_STORE_CONNECT_API_KEY_ISSUER_ID'], 'iat': int(time.time()), 'exp': int(time.time())+600, 'aud': 'appstoreconnect-v1'}, base64.b64decode(os.environ['APP_STORE_CONNECT_API_KEY_BASE64']), algorithm='ES256', headers={'kid':os.environ['APP_STORE_CONNECT_API_KEY_ID']})
    r=requests.get('https://api.appstoreconnect.apple.com/v1'+path,headers={'Authorization':'Bearer '+token},timeout=45)
    if not r.ok: print(r.status_code,r.text[:2000]);r.raise_for_status()
    return r.json()['data']
apps=api('/apps?filter[bundleId]=com.snarfnet.goauniverse')
assert len(apps)==1
app=apps[0];print('APP',app['id'],app['attributes']['name'])
for x in api('/apps/'+app['id']+'/appStoreVersions?limit=10'):
    print('VERSION',x['id'],json.dumps(x['attributes']))
for x in api('/builds?filter[app]='+app['id']+'&sort=-uploadedDate&limit=5'):
    print('BUILD',x['id'],json.dumps(x['attributes']))
