#!/usr/bin/env python3
import hashlib
import json
import os
import sys
import time
from datetime import date
from pathlib import Path

import jwt
import requests

BASE_URL = "https://api.appstoreconnect.apple.com/v1"
KEY_ID = os.environ.get("ASC_KEY_ID", "WDXGY9WX55")
ISSUER_ID = os.environ.get("ASC_ISSUER_ID", "2be0734f-943a-4d61-9dc9-5d9045c46fec")
KEY_PATH = Path(os.environ.get("ASC_KEY_PATH", r"C:\Users\Windows\.appstoreconnect\private_keys\AuthKey_WDXGY9WX55.p8"))
APP_ID = os.environ.get("ASC_APP_ID", "6770217114")
VERSION_ID = os.environ.get("ASC_VERSION_ID", "b79c5ee5-8eb6-4131-aacc-a533b9052e17")
LOCALIZATION_ID = os.environ.get("ASC_VERSION_LOCALIZATION_ID", "b7185697-67f3-4b30-8e77-296fc76b1fd2")
SCREENSHOT_PATH = Path(os.environ.get("ASC_SCREENSHOT_PATH", r"C:\Users\Windows\GOA_UNIVERSE\AppStore\Screenshots\iphone65-1.png"))
BUILD_ID = os.environ.get("ASC_BUILD_ID")
BUILD_NUMBER = os.environ.get("ASC_BUILD_NUMBER", "2")
AGE_RATING_ID = os.environ.get("ASC_AGE_RATING_ID", "00ca3f57-d891-4389-b8ef-812dd9c24867")


def token() -> str:
    now = int(time.time())
    payload = {
        "iss": ISSUER_ID,
        "iat": now,
        "exp": now + 20 * 60,
        "aud": "appstoreconnect-v1",
    }
    return jwt.encode(payload, KEY_PATH.read_text(encoding="utf-8"), algorithm="ES256", headers={"kid": KEY_ID})


def api(method: str, path: str, body: dict | None = None, ok: tuple[int, ...] = (200, 201, 204)) -> requests.Response:
    response = requests.request(
        method,
        f"{BASE_URL}{path}",
        headers={
            "Authorization": f"Bearer {token()}",
            "Content-Type": "application/json",
        },
        json=body,
        timeout=60,
    )
    if response.status_code not in ok:
        raise RuntimeError(format_error(response))
    return response


def format_error(response: requests.Response) -> str:
    lines = [f"HTTP {response.status_code}"]
    try:
        payload = response.json()
    except Exception:
        return "\n".join(lines + [response.text[:2000]])
    for error in payload.get("errors", []):
        pointer = error.get("source", {}).get("pointer", "")
        title = error.get("title", "Error")
        detail = error.get("detail", "")
        code = error.get("code", "")
        lines.append(f"- {title} {f'({code})' if code else ''}: {detail} {pointer}".strip())
        for associated in error.get("meta", {}).get("associatedErrors", []):
            if not isinstance(associated, dict):
                lines.append(f"  - {associated}")
                continue
            associated_title = associated.get("title", "Associated error")
            associated_detail = associated.get("detail", "")
            associated_pointer = associated.get("source", {}).get("pointer", "")
            lines.append(f"  - {associated_title}: {associated_detail} {associated_pointer}".strip())
    return "\n".join(lines)


def data(response: requests.Response) -> dict:
    return response.json()["data"]


def patch_version_metadata() -> None:
    body = {
        "data": {
            "type": "appStoreVersions",
            "id": VERSION_ID,
            "attributes": {
                "copyright": "© 2026 snarfnet",
                "usesIdfa": True,
                "releaseType": "AFTER_APPROVAL",
            },
        }
    }
    api("PATCH", f"/appStoreVersions/{VERSION_ID}", body)


def patch_app_metadata() -> None:
    body = {
        "data": {
            "type": "apps",
            "id": APP_ID,
            "attributes": {"contentRightsDeclaration": "DOES_NOT_USE_THIRD_PARTY_CONTENT"},
        }
    }
    api("PATCH", f"/apps/{APP_ID}", body)


def patch_build_metadata() -> None:
    build_id = get_build_id()
    body = {
        "data": {
            "type": "builds",
            "id": build_id,
            "attributes": {"usesNonExemptEncryption": False},
        }
    }
    try:
        api("PATCH", f"/builds/{build_id}", body)
    except RuntimeError as exc:
        if "usesNonExemptEncryption" not in str(exc):
            raise


def get_build_id() -> str:
    if BUILD_ID:
        return BUILD_ID

    for _ in range(60):
        response = api("GET", f"/builds?filter[app]={APP_ID}&sort=-uploadedDate&limit=10")
        for item in response.json().get("data", []):
            attributes = item.get("attributes", {})
            if attributes.get("version") == BUILD_NUMBER and attributes.get("processingState") == "VALID":
                return item["id"]
        print(f"Waiting for build {BUILD_NUMBER} to finish processing...")
        time.sleep(30)
    raise RuntimeError(f"Build {BUILD_NUMBER} did not become VALID in time.")


def assign_build_to_version() -> None:
    build_id = get_build_id()
    body = {"data": {"type": "builds", "id": build_id}}
    api("PATCH", f"/appStoreVersions/{VERSION_ID}/relationships/build", body, ok=(204,))


def patch_age_rating() -> None:
    body = {
        "data": {
            "type": "ageRatingDeclarations",
            "id": AGE_RATING_ID,
            "attributes": {
                "advertising": True,
                "alcoholTobaccoOrDrugUseOrReferences": "NONE",
                "contests": "NONE",
                "gambling": False,
                "gamblingSimulated": "NONE",
                "gunsOrOtherWeapons": "NONE",
                "healthOrWellnessTopics": False,
                "lootBox": False,
                "medicalOrTreatmentInformation": "NONE",
                "messagingAndChat": False,
                "parentalControls": False,
                "profanityOrCrudeHumor": "NONE",
                "ageAssurance": False,
                "sexualContentGraphicAndNudity": "NONE",
                "sexualContentOrNudity": "NONE",
                "horrorOrFearThemes": "NONE",
                "matureOrSuggestiveThemes": "NONE",
                "unrestrictedWebAccess": False,
                "userGeneratedContent": False,
                "violenceCartoonOrFantasy": "NONE",
                "violenceRealisticProlongedGraphicOrSadistic": "NONE",
                "violenceRealistic": "NONE",
            },
        }
    }
    api("PATCH", f"/ageRatingDeclarations/{AGE_RATING_ID}", body)


def ensure_review_detail() -> None:
    attributes = {
        "contactFirstName": "Satoshi",
        "contactLastName": "Amasaki",
        "contactEmail": "snarfnet@gmail.com",
        "contactPhone": "+81 80 2368 9194",
        "demoAccountRequired": False,
        "notes": "Music generator app. No account needed. The app analyzes a selected audio file on device and generates a Goa trance pattern. The App Tracking Transparency permission request appears on launch before the Google AdMob banner loads.",
    }
    existing = api("GET", f"/appStoreVersions/{VERSION_ID}/appStoreReviewDetail")
    current = existing.json().get("data")
    if current:
        body = {
            "data": {
                "type": "appStoreReviewDetails",
                "id": current["id"],
                "attributes": attributes,
            }
        }
        api("PATCH", f"/appStoreReviewDetails/{current['id']}", body)
        return

    body = {
        "data": {
            "type": "appStoreReviewDetails",
            "attributes": attributes,
            "relationships": {
                "appStoreVersion": {"data": {"type": "appStoreVersions", "id": VERSION_ID}}
            },
        }
    }
    api("POST", "/appStoreReviewDetails", body)


def get_free_price_point() -> str:
    response = api("GET", f"/apps/{APP_ID}/appPricePoints?filter[territory]=USA&limit=200")
    for item in response.json().get("data", []):
        if item.get("attributes", {}).get("customerPrice") in {"0.0", "0.00"}:
            return item["id"]
    raise RuntimeError("Free USA app price point was not found.")


def ensure_free_price() -> None:
    response = api("GET", f"/appPriceSchedules/{APP_ID}/manualPrices?include=appPricePoint&limit=50", ok=(200, 404))
    if response.status_code == 200:
        included = response.json().get("included", [])
        if any(item.get("type") == "appPricePoints" and item.get("attributes", {}).get("customerPrice") in {"0.0", "0.00"} for item in included):
            return

    price_point_id = get_free_price_point()
    body = {
        "data": {
            "type": "appPriceSchedules",
            "relationships": {
                "app": {"data": {"type": "apps", "id": APP_ID}},
                "baseTerritory": {"data": {"type": "territories", "id": "USA"}},
                "manualPrices": {"data": [{"type": "appPrices", "id": "${free-price}"}]},
            },
        },
        "included": [
            {
                "type": "appPrices",
                "id": "${free-price}",
                "attributes": {"startDate": date.today().isoformat()},
                "relationships": {
                    "appPricePoint": {"data": {"type": "appPricePoints", "id": price_point_id}},
                },
            }
        ],
    }
    api("POST", "/appPriceSchedules", body, ok=(201, 409))


def list_screenshot_sets() -> list[dict]:
    response = api(
        "GET",
        f"/appStoreVersionLocalizations/{LOCALIZATION_ID}/appScreenshotSets?include=appScreenshots&limit=20",
    )
    return response.json().get("data", [])


def create_screenshot_set() -> str:
    body = {
        "data": {
            "type": "appScreenshotSets",
            "attributes": {"screenshotDisplayType": "APP_IPHONE_65"},
            "relationships": {
                "appStoreVersionLocalization": {
                    "data": {"type": "appStoreVersionLocalizations", "id": LOCALIZATION_ID}
                }
            },
        }
    }
    return data(api("POST", "/appScreenshotSets", body))["id"]


def screenshot_set_id() -> str:
    for item in list_screenshot_sets():
        if item.get("attributes", {}).get("screenshotDisplayType") == "APP_IPHONE_65":
            return item["id"]
    return create_screenshot_set()


def delete_existing_screenshots(set_id: str) -> None:
    response = api("GET", f"/appScreenshotSets/{set_id}/appScreenshots?limit=50")
    for item in response.json().get("data", []):
        api("DELETE", f"/appScreenshots/{item['id']}", ok=(204,))


def existing_uploaded_screenshot(set_id: str) -> str | None:
    response = api("GET", f"/appScreenshotSets/{set_id}/appScreenshots?limit=50")
    for item in response.json().get("data", []):
        state = item.get("attributes", {}).get("assetDeliveryState", {}).get("state")
        if state in {"UPLOAD_COMPLETE", "COMPLETE"}:
            return item["id"]
    return None


def reserve_screenshot(set_id: str) -> dict:
    size = SCREENSHOT_PATH.stat().st_size
    body = {
        "data": {
            "type": "appScreenshots",
            "attributes": {
                "fileName": SCREENSHOT_PATH.name,
                "fileSize": size,
            },
            "relationships": {
                "appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": set_id}}
            },
        }
    }
    return data(api("POST", "/appScreenshots", body))


def upload_parts(reservation: dict) -> None:
    file_bytes = SCREENSHOT_PATH.read_bytes()
    for operation in reservation["attributes"]["uploadOperations"]:
        start = int(operation["offset"])
        length = int(operation["length"])
        chunk = file_bytes[start:start + length]
        headers = {header["name"]: header["value"] for header in operation.get("requestHeaders", [])}
        response = requests.request(operation["method"], operation["url"], headers=headers, data=chunk, timeout=120)
        if response.status_code not in (200, 201):
            raise RuntimeError(f"Upload failed: HTTP {response.status_code}\n{response.text[:1000]}")


def commit_screenshot(screenshot_id: str) -> None:
    checksum = hashlib.md5(SCREENSHOT_PATH.read_bytes()).hexdigest()
    body = {
        "data": {
            "type": "appScreenshots",
            "id": screenshot_id,
            "attributes": {
                "uploaded": True,
                "sourceFileChecksum": checksum,
            },
        }
    }
    api("PATCH", f"/appScreenshots/{screenshot_id}", body)


def wait_for_screenshot(screenshot_id: str) -> None:
    for _ in range(30):
        item = data(api("GET", f"/appScreenshots/{screenshot_id}"))
        state = item.get("attributes", {}).get("assetDeliveryState", {})
        name = state.get("state")
        errors = state.get("errors") or []
        if errors:
            raise RuntimeError(json.dumps(errors, ensure_ascii=False, indent=2))
        if name in {"COMPLETE", "UPLOAD_COMPLETE"}:
            print(f"Screenshot state: {name}")
            return
        print(f"Screenshot state: {name}")
        time.sleep(10)


def active_review_submission() -> str | None:
    response = api("GET", f"/apps/{APP_ID}/reviewSubmissions?limit=10")
    for item in response.json().get("data", []):
        state = item.get("attributes", {}).get("state")
        if state in {"READY_FOR_REVIEW", "WAITING_FOR_REVIEW", "IN_REVIEW", "UNRESOLVED_ISSUES"}:
            return item["id"]
    return None


def create_review_submission() -> str:
    existing = active_review_submission()
    if existing:
        return existing
    body = {
        "data": {
            "type": "reviewSubmissions",
            "relationships": {"app": {"data": {"type": "apps", "id": APP_ID}}},
        }
    }
    return data(api("POST", "/reviewSubmissions", body))["id"]


def create_review_item(submission_id: str) -> None:
    body = {
        "data": {
            "type": "reviewSubmissionItems",
            "relationships": {
                "reviewSubmission": {"data": {"type": "reviewSubmissions", "id": submission_id}},
                "appStoreVersion": {"data": {"type": "appStoreVersions", "id": VERSION_ID}},
            },
        }
    }
    try:
        api("POST", "/reviewSubmissionItems", body)
    except RuntimeError as exc:
        message = str(exc).lower()
        if "already" in message or "does not allow adding more items" in message:
            return
        raise


def resolve_rejected_items(submission_id: str) -> None:
    response = api("GET", f"/reviewSubmissions/{submission_id}/items?limit=50")
    for item in response.json().get("data", []):
        if item.get("attributes", {}).get("state") != "REJECTED":
            continue
        body = {
            "data": {
                "type": "reviewSubmissionItems",
                "id": item["id"],
                "attributes": {"resolved": True},
            }
        }
        api("PATCH", f"/reviewSubmissionItems/{item['id']}", body)


def submit_review(submission_id: str) -> None:
    body = {
        "data": {
            "type": "reviewSubmissions",
            "id": submission_id,
            "attributes": {"submitted": True},
        }
    }
    api("PATCH", f"/reviewSubmissions/{submission_id}", body)


def main() -> None:
    if not SCREENSHOT_PATH.exists():
        raise SystemExit(f"Screenshot not found: {SCREENSHOT_PATH}")

    patch_version_metadata()
    patch_app_metadata()
    assign_build_to_version()
    patch_build_metadata()
    patch_age_rating()
    ensure_review_detail()
    ensure_free_price()

    set_id = screenshot_set_id()
    print(f"Screenshot set: {set_id}")
    screenshot_id = existing_uploaded_screenshot(set_id)
    if screenshot_id:
        print(f"Screenshot already uploaded: {screenshot_id}")
    else:
        delete_existing_screenshots(set_id)
        reservation = reserve_screenshot(set_id)
        print(f"Screenshot reservation: {reservation['id']}")
        upload_parts(reservation)
        commit_screenshot(reservation["id"])
        wait_for_screenshot(reservation["id"])

    submission_id = create_review_submission()
    print(f"Review submission: {submission_id}")
    create_review_item(submission_id)
    resolve_rejected_items(submission_id)
    submit_review(submission_id)
    print("Submitted for review.")


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print(str(exc), file=sys.stderr)
        sys.exit(1)
