# ASC App Creation

Use these values when creating the app in App Store Connect.

## New App

Platform:
iOS

Name:
GOA UNIVERSE

Primary language:
Japanese

Bundle ID:
com.snarfnet.goauniverse

SKU:
goa-universe-ios

User Access:
Full Access

## Categories

Primary category:
Music

Secondary category:
Entertainment

## Pricing

Price:
Free

Reason:
The app uses AdMob banner ads.

## App Privacy

Do not choose "Data Not Collected".

Use the AdMob-enabled privacy notes in:
ASC_SUBMISSION.md

## Before Uploading a Build

1. Register `com.snarfnet.goauniverse` in Apple Developer if it is not listed yet.
2. Open `GOA_UNIVERSE.xcodeproj` in Xcode.
3. Set your Apple Team in Signing & Capabilities.
4. Confirm bundle identifier is `com.snarfnet.goauniverse`.
5. Resolve packages.
6. Archive.
7. Distribute App > App Store Connect.

GitHub simulator build already passed:
https://github.com/snarfnet/GOA_UNIVERSE/actions/runs/25984477739
