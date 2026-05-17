#!/usr/bin/env python3
import json
import os
import sys
import time
from pathlib import Path
from urllib.parse import quote

import jwt
import requests

KEY_ID = os.environ.get("ASC_KEY_ID", "WDXGY9WX55")
ISSUER_ID = os.environ.get("ASC_ISSUER_ID", "2be0734f-943a-4d61-9dc9-5d9045c46fec")
KEY_PATH = Path(os.environ.get(
    "ASC_KEY_PATH",
    r"C:\Users\Windows\.appstoreconnect\private_keys\AuthKey_WDXGY9WX55.p8",
))

BUNDLE_IDENTIFIER = os.environ.get("ASC_BUNDLE_ID", "com.snarfnet.goauniverse")
BUNDLE_NAME = os.environ.get("ASC_BUNDLE_NAME", "GOA UNIVERSE")
BASE_URL = "https://api.appstoreconnect.apple.com/v1"


def token() -> str:
    now = int(time.time())
    private_key = KEY_PATH.read_text(encoding="utf-8")
    payload = {
        "iss": ISSUER_ID,
        "iat": now,
        "exp": now + 20 * 60,
        "aud": "appstoreconnect-v1",
    }
    return jwt.encode(payload, private_key, algorithm="ES256", headers={"kid": KEY_ID})


def request(method: str, path: str, body: dict | None = None) -> requests.Response:
    headers = {
        "Authorization": f"Bearer {token()}",
        "Content-Type": "application/json",
    }
    return requests.request(method, f"{BASE_URL}{path}", headers=headers, json=body, timeout=30)


def print_error(response: requests.Response) -> None:
    print(f"Apple API error: HTTP {response.status_code}")
    try:
        payload = response.json()
    except Exception:
        print(response.text[:1000])
        return

    for error in payload.get("errors", []):
        title = error.get("title", "Error")
        detail = error.get("detail", "")
        code = error.get("code", "")
        print(f"- {title} {f'({code})' if code else ''}: {detail}")


def find_existing() -> dict | None:
    encoded = quote(BUNDLE_IDENTIFIER, safe="")
    response = request("GET", f"/bundleIds?filter[identifier]={encoded}&limit=1")
    if response.status_code != 200:
        print_error(response)
        sys.exit(1)

    data = response.json().get("data", [])
    return data[0] if data else None


def create_bundle_id() -> dict:
    body = {
        "data": {
            "type": "bundleIds",
            "attributes": {
                "name": BUNDLE_NAME,
                "identifier": BUNDLE_IDENTIFIER,
                "platform": "IOS",
            },
        }
    }
    response = request("POST", "/bundleIds", body)
    if response.status_code not in (200, 201):
        print_error(response)
        sys.exit(1)

    return response.json()["data"]


def main() -> None:
    if not KEY_PATH.exists():
        print(f"API key file not found: {KEY_PATH}")
        sys.exit(1)

    existing = find_existing()
    if existing:
        attrs = existing.get("attributes", {})
        print("Bundle ID already exists.")
        print(json.dumps({
            "id": existing.get("id"),
            "name": attrs.get("name"),
            "identifier": attrs.get("identifier"),
            "platform": attrs.get("platform"),
        }, ensure_ascii=False, indent=2))
        return

    created = create_bundle_id()
    attrs = created.get("attributes", {})
    print("Bundle ID registered.")
    print(json.dumps({
        "id": created.get("id"),
        "name": attrs.get("name"),
        "identifier": attrs.get("identifier"),
        "platform": attrs.get("platform"),
    }, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
