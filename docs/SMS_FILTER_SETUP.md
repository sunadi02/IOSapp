# SMS scam filter: setting up the extension

ScamShield's SMS filter is an iOS Message Filter extension built on Apple's Identity Lookup framework. iOS hands the extension the text of messages from senders who are not in the user's contacts, and the extension answers "Junk" or "no opinion". It cannot read any other message, and it works fully offline.

All of the decision logic is already in the app, in `ScamShield/Services/Analysis/SMSFilterDecision.swift`, and is unit tested. The extension itself is a thin wrapper around it. A new extension target can only be created in Xcode, so it is a one time manual step.

## 1. Create the extension target

1. Open `ScamShield.xcodeproj` in Xcode.
2. Choose **File, New, Target**, pick **iOS**, then **Message Filter Extension**, and press Next.
3. Product Name: `ScamShieldSMSFilter`. Team: your Personal Team. Language: Swift. Press Finish.
4. When Xcode asks to activate the new scheme, choose **Cancel** so the `ScamShield` scheme stays active.

Xcode creates a `ScamShieldSMSFilter` folder with `MessageFilterExtension.swift` and an `Info.plist`, and embeds the extension in the app.

## 2. Replace the generated code

Open `ScamShieldSMSFilter/MessageFilterExtension.swift` and replace everything in it with:

```swift
import IdentityLookup

final class MessageFilterExtension: ILMessageFilterExtension {}

extension MessageFilterExtension: ILMessageFilterQueryHandling {

    func handle(
        _ queryRequest: ILMessageFilterQueryRequest,
        context: ILMessageFilterExtensionContext,
        completion: @escaping (ILMessageFilterQueryResponse) -> Void
    ) {
        let response = ILMessageFilterQueryResponse()

        switch SMSFilterDecision.action(for: queryRequest.messageBody, sender: queryRequest.sender) {
        case .junk: response.action = .junk
        case .none: response.action = .none
        }

        completion(response)
    }
}
```

It never calls `deferQueryRequestToNetwork`, so a text is never sent anywhere.

## 3. Clean up the extension settings

1. In `ScamShieldSMSFilter/Info.plist`, open `NSExtension`, then `NSExtensionAttributes`, and delete the `ILMessageFilterExtensionNetworkURL` row if it is there.
2. Select the project, then the `ScamShieldSMSFilter` target, then **Build Settings**:
   - Set **iOS Deployment Target** to `17.6`, the same as the app.
   - Search for "isolation". If **Default Actor Isolation** shows MainActor, change it to **nonisolated**.

## 4. Share the decision code with the extension

The extension reuses some app files. For each file below, click it in the Xcode navigator, open the File Inspector (Option Command 1), and under **Target Membership** tick `ScamShieldSMSFilter`. Leave `ScamShield` ticked.

- `Models/RiskSignal.swift`
- `Models/RiskLevel.swift`
- `Models/ScanType.swift`
- `Models/ScanResult.swift`
- `Services/Analysis/URLAnalyzer.swift`
- `Services/Analysis/RiskScorer.swift`
- `Services/Analysis/LinkExtractor.swift`
- `Services/Analysis/SMSFilterDecision.swift`

## 5. Build and run

1. Pick the `ScamShield` scheme and your iPhone, then press Command B. Fix any "cannot find" error by checking that file's target membership.
2. Press Command R to install the app on the iPhone.
3. On the iPhone open **Settings, Messages, Unknown & Spam**. Turn on **Filter Unknown Senders**, then under **SMS Filtering** choose **ScamShield**.

## 6. Test it

Ask a friend, or use a second phone that is not in your contacts, to send a plain SMS (not an iMessage):

- `URGENT: your account will be suspended. Share your OTP now` should land in **Messages, Filters, Junk**.
- `Hi, are we meeting for lunch tomorrow?` should arrive normally.

The app's Settings, SMS Scam Filter screen has a "Try it" box that runs the same rules without needing a second phone.

## Notes for the report

- The extension is limited to texts from unknown senders, and it only sees the text and sender name that iOS passes in.
- Wording rules are plain text matching (no NaturalLanguage or Core ML) because Message Filter extensions run in a small, short lived process.
- A text is moved to Junk only when the app would call it Risky. Everything else is left to iOS, and nothing is ever deleted.
- The filter cannot read the app's settings, because sharing data between an app and its extension needs an App Group, which a free developer account does not allow.
