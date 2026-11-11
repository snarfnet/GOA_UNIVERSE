import os, time, base64, json, sys
import jwt, requests

def api(path, method="GET", body=None):
    token = jwt.encode({'iss': os.environ['APP_STORE_CONNECT_API_KEY_ISSUER_ID'], 'iat': int(time.time()), 'exp': int(time.time())+600, 'aud': 'appstoreconnect-v1'}, base64.b64decode(os.environ['APP_STORE_CONNECT_API_KEY_BASE64']), algorithm='ES256', headers={'kid':os.environ['APP_STORE_CONNECT_API_KEY_ID']})
    r=requests.request(method,'https://api.appstoreconnect.apple.com/v1'+path,headers={'Authorization':'Bearer '+token},json=body,timeout=45)
    if not r.ok: print(r.status_code,r.text[:2000]);r.raise_for_status()
    return r.json()['data'] if r.content else None
apps=api('/apps?filter[bundleId]=com.snarfnet.goauniverse')
assert len(apps)==1
app=apps[0];print('APP',app['id'],app['attributes']['name'])
for x in api('/apps/'+app['id']+'/appStoreVersions?limit=10'):
    print('VERSION',x['id'],json.dumps(x['attributes']))
for x in api('/builds?filter[app]='+app['id']+'&sort=-uploadedDate&limit=5'):
    print('BUILD',x['id'],json.dumps(x['attributes']))

if os.environ.get('ASC_ACTION') == 'prepare':
    versions=api('/apps/'+app['id']+'/appStoreVersions?limit=20')
    current=next(x for x in versions if x['attributes']['versionString']=='1.0')
    target=next((x for x in versions if x['attributes']['versionString']=='1.1'),None)
    if target is None:
        target=api('/appStoreVersions','POST',{'data':{'type':'appStoreVersions','attributes':{'platform':'IOS','versionString':'1.1','copyright':current['attributes']['copyright'],'releaseType':current['attributes']['releaseType'],'usesIdfa':current['attributes']['usesIdfa']},'relationships':{'app':{'data':{'type':'apps','id':app['id']}}}}})
    assert target['attributes']['appStoreState'] == 'PREPARE_FOR_SUBMISSION'
    for loc in api('/appStoreVersions/'+target['id']+'/appStoreVersionLocalizations'):
        locale=loc['attributes']['locale']
        note = '6種類のシンセ音色を追加しました。Classic・Acid・Celestialの3セットを選べます。3分のデモ曲を書き出し、WAVで共有できるようになりました。' if locale=='ja' else 'Added six synth sounds with Classic, Acid and Celestial sound banks. Export a three-minute demo arrangement as a WAV file and share it from the app.'
        api('/appStoreVersionLocalizations/'+loc['id'],'PATCH',{'data':{'type':'appStoreVersionLocalizations','id':loc['id'],'attributes':{'whatsNew':note}}})
        print('UPDATED_LOCALE',locale)
    print('PREPARED_VERSION',target['id'])
print('LUMI_STATUS')
for x in api('/apps/6831554518/appStoreVersions?limit=10'):
    print('LUMI_VERSION',x['id'],json.dumps(x['attributes']))
