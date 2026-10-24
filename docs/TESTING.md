# Testing notes (for the report)

## Approach

- **Swift Testing** (`import Testing`, `@Test`, `#expect`, `#require`) is used for every unit test, as the brief asks. Apple's accessibility audit in `ScamShieldUITests` is the one exception: UI automation is only available through XCTest.
- **Logic lives in view models and services, not in views.** Views stay thin, so the rules (scoring, parsing, syncing, sorting, wording) can be tested without a screen.
- **Every outside dependency sits behind a protocol** (`LinkReputationChecking`, `HistoryStoring`, `AuthServicing`, `CommunityReporting`, `RemoteHistoryStoring`, `NotificationScheduling`, `BiometricAuthenticating`, `CameraControlling`, `BarcodeDetecting`, `TextRecognizing`, `ScamClassifying`). Tests pass a fake from `ScamShieldTests/Mocks.swift`, so no test needs the internet, Firebase, a camera, or Face ID.
- **Real frameworks are used where they can run on their own**: Core Data (an in-memory store per test), Vision (QR codes and text drawn inside the test), NaturalLanguage, `URLSession` (answered by `StubURLProtocol`), and `NSDataDetector`.
- **Each test makes its own state.** Every suite builds a fresh in-memory store and its own `UserDefaults` suite, and the stubbed web requests are keyed by a unique id. Tests can therefore run side by side in any order.
- **Dates and time zones are fixed** in time-based tests (a set date in Asia/Colombo), so results do not depend on when they run.

## What is covered

| Area | Suites |
|---|---|
| Link analysis and scoring | `URLAnalyzerTests`, `RiskScorerTests`, `LinkScannerTests`, `LinkScannerCommunityTests`, `ScanResultTests`, `RiskStyleTests` |
| Google Safe Browsing | `SafeBrowsingServiceTests` (request and response shapes), `SafeBrowsingNetworkTests` (real `URLSession` against a stub: success, error codes, offline, bad data) |
| Storage and sync | `HistoryRepositoryTests`, `PersistenceControllerTests`, `HistorySyncServiceTests`, `FirestoreHistoryRemoteTests` |
| Accounts and security | `AuthViewModelTests`, `AppLockViewModelTests` and `BiometricErrorTests`, `AppSecretsTests` |
| Screens' logic | `DashboardViewModelTests` (including the weekly chart), `HistoryViewModelTests`, `CheckLinkViewModelTests`, `SettingsViewModelTests`, `CommunityViewModelTests`, `ReportViewModelTests`, `QRScannerViewModelTests`, `ScreenshotScanViewModelTests`, `AppSectionTests` |
| Scanning | `QRPayloadParserTests`, `QRScannerTests`, `BarcodeDetectorTests`, `TextRecognizerTests`, `LinkExtractorTests` |
| On-device language analysis | `MessageAnalyzerTests`, `MessageScannerTests`, `ScamClassifierTests`, `SMSFilterDecisionTests` |
| Notifications and background work | `RecheckServiceTests`, `NotificationRouterTests`, `NetworkMonitorTests` |
| Community | `FirestoreCommunityServiceTests`, `CommunityViewModelTests`, `ReportViewModelTests` |
| Siri and Shortcuts | `LinkVerdictSummaryTests`, `IntentLinkCheckerTests` |
| Accessibility and motion | `AccessibilityTextTests`, `ResultMotionTests`, `AccessibilityAuditTests` (UI) |

## Edge cases worth pointing out

- Boundaries of the verdict: scores 49, 50, 79 and 80, verified and unverified.
- A genuine bank warning ("Do not share your OTP") must not be flagged, while "Share your OTP" must.
- A message with no links and a link that could not be checked online can never be called Safe.
- Wi-Fi passwords in a QR code are never stored, and scanned message text is never spoken, shared, or uploaded.
- A deleted scan stays deleted even when the cloud cannot be reached at the time.
- Malformed data is skipped rather than crashing: broken property lists, bad Firestore documents, and non-JSON answers.

## Running the tests

1. Open `ScamShield.xcodeproj` and choose the `ScamShield` scheme with an iPhone simulator.
2. Press Command U.
3. Code coverage is already switched on in the scheme and limited to the app target. After the run open the Report navigator (Command 9), pick the test run, and choose the **Coverage** tab. Expand `ScamShield.app` to see each file. Screenshot this for the report.

## Left out on purpose

These need hardware or a live service, so they are checked by hand and by the logic around them:

- The live camera feed (the parsing, Vision decoding and screen logic are tested; the `AVCaptureSession` is not).
- Face ID itself (`LAContext`); its error handling is tested through a fake.
- Delivering a real notification, and the Firestore network calls (the data mapping and sync logic are tested through a fake).
- The SMS filter extension running inside iOS (the decision it calls is tested).
- Pure SwiftUI layout. Accessibility and Dynamic Type are checked with the audit test and by hand.

## Tests that use the real Apple engines

A few suites run Vision text recognition, Vision QR decoding, language detection and the lemmatiser on the simulator: `TextRecognizerTests`, `BarcodeDetectorTests`, `MessageAnalyzerTests`, and the language cases in `MessageScannerTests`. If one fails on a different iOS version, check whether Apple's model changed before assuming the app is wrong.
