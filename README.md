# ScamShield

ScamShield is an iOS app that checks links, QR codes and message screenshots for scams before you act on them. Each check gives a clear result (Safe, Risky or Unknown), a trust score out of 100, and the reasons behind the verdict.

Built by M.S.A.A. Sunadi Amarasinghe (COBSCCOMP251P-008) for the NIBM iOS Application Development module.

## Features

| Area | What it does |
|---|---|
| Onboarding and sign-in | Intro slides, then email and password accounts with Firebase Authentication |
| Dashboard | Greeting, protection status, a Scan button, today's stats, a weekly chart, quick actions and recent scans |
| Link check | On-device URL rules plus Google Safe Browsing, combined into one trust score |
| QR scanner | Camera scanning with Vision; handles web links, Wi-Fi, SMS, phone, email and payment codes |
| Screenshot scan | Vision OCR reads the text, then Natural Language rules and a Core ML model judge the wording |
| Results | Trust score ring, risk badge, reasons sorted by severity, share, copy and report |
| History | Core Data storage, search, filters, swipe to delete with undo, CSV export |
| Cloud sync | Link and QR history synced to Firestore; screenshot text never leaves the device |
| Community | Report scam websites and see what others reported in the last week |
| Scam alerts | Saved links are re-checked, with a local notification if one is later flagged |
| App lock | Face ID with device passcode fallback; content hidden in the app switcher |
| SMS filter | Message Filter extension that moves scam texts from unknown senders to Junk |
| System integration | Siri and Shortcuts (App Intents), Spotlight search, Home Screen quick actions, copied-link detection |
| Multi-device | Tab bar on iPhone, sidebar and side-by-side history on iPad |
| Appearance | Light, Dark or System, with Dynamic Type, VoiceOver and Reduce Motion support |

## Requirements

- Xcode 27 or later
- iOS 17.6 or later (iPhone or iPad)
- A Firebase project with Authentication (Email/Password) and Cloud Firestore
- A Google Cloud API key with the Safe Browsing API enabled

## Setup

Two configuration files are kept out of git and must be added before building.

1. **Firebase:** download `GoogleService-Info.plist` for the bundle ID `sunadi.ScamShield` from the Firebase Console and place it in `ScamShield/`.
2. **Safe Browsing key:** copy `ScamShield/Config/Secrets.example.plist` to `ScamShield/Config/Secrets.plist` and replace the placeholder with your API key.
3. **Firestore rules:** publish the contents of `firestore.rules` in Firebase Console, under Firestore Database, then Rules.
4. **Signing:** select your team for both the `ScamShield` and `ScamShieldSMSFilter` targets under Signing & Capabilities.
5. Open `ScamShield.xcodeproj`, choose the `ScamShield` scheme and run.

Without `Secrets.plist`, link checks still work but use on-device rules only, so results stay Unknown rather than Safe.

## Running the tests

The unit tests use the Swift Testing framework. In Xcode, choose Product, then Test (⌘U). The tests use in-memory Core Data and mocks, so they need no network or Firebase access.

## Project structure

```
ScamShield/
  App/            App entry point, app delegate, menu commands
  Config/         API key loading
  Intents/        Siri and Shortcuts actions
  ML/             Compiled Core ML scam message model
  Models/         ScanResult, RiskSignal, RiskLevel, ScanType, ScamReport
  Persistence/    Core Data stack and the synced history store
  Services/       Analysis, scanning, network, sync, community, security, notifications
  ViewModels/     One view model per screen
  Views/          SwiftUI screens and shared components
ScamShieldSMSFilter/  Message Filter extension
ScamShieldTests/      Swift Testing unit tests
ML/                   Training data and script for the Core ML model
firestore.rules       Firestore security rules
```

The app uses MVVM. Services sit behind protocols so view models can be tested with mocks.

## How a verdict is made

Every check produces a list of signals, each with a weight. The trust score is 100 minus the total weight, kept between 0 and 100.

- Below 50 is **Risky**.
- 80 or more is **Safe**, but only if the online check finished.
- Anything else is **Unknown**.

Link signals include missing HTTPS, raw IP addresses, lookalike characters, hidden destinations, short links, unusual domain endings, brand impersonation and Google Safe Browsing matches. Message signals include pressure to act, prize or refund offers, threats, requests for OTPs or PINs, delivery fee requests, brand names with unofficial links, and the Core ML model's score.

## Privacy

- Message text and screenshots are analysed on the device and are never uploaded.
- Only link addresses are sent to Google Safe Browsing.
- Community reports share only the website address, with the query and fragment removed.
- Firestore rules limit each user to their own history, and reports cannot be edited or deleted.

## Retraining the model

See `ML/README.md`. In short, run `swift ML/train.swift` from the project root to rebuild `ScamShield/ML/ScamTextClassifier.mlmodel`.

## Known limitations

- Sign in with Apple is not included because it needs a paid Apple Developer account.
- The scam model reads English only. Sinhala and Tamil messages are marked as not fully checked.
- iOS only passes SMS from unknown senders to filter extensions. iMessages are never filtered.
- Scam alerts run when the app opens, at most every six hours, rather than in the background.

## Credits

- SMS Spam Collection v.1, UCI Machine Learning Repository, CC BY 4.0 (Almeida, Gómez Hidalgo and Yamakami, 2011).
- Google Safe Browsing API v4.
- Firebase Authentication and Cloud Firestore.
