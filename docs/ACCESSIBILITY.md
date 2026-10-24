# Accessibility notes (for the report)

ScamShield is built so that a scan result can be understood without seeing the screen, without small text, and without colour.

## VoiceOver

- **Every scan has a spoken summary.** A row in History reads as, for example, "Link https://evil.com, Risky, trust score 20, 2 hours ago". A scanned message is never read out loud, only "Message screenshot".
- **Results are announced.** When a scan finishes, VoiceOver says "Scan finished. Risky. Trust score 20 out of 100." as soon as the result opens, so the verdict does not depend on finding it on screen.
- **Errors are announced.** A bad link, a failed sign in, a photo with no QR code and similar messages are spoken when they appear. Before this, they showed up silently.
- **Grouped elements.** Stat cards, scan rows, signals and the trust ring are each one element with a full sentence, instead of many fragments. The ring always speaks its final score, not the half filled value while it animates.
- **Decorative images are hidden.** Icons that only repeat nearby text are removed from the VoiceOver order.
- **Headings.** Section titles on the dashboard are marked as headings so the rotor can jump between them.
- **The weekly chart** has a text summary ("5 scans in the last 7 days: 3 safe, 1 risky, 1 unknown") and supports Audio Graphs.
- **Hidden or covered content.** While the app lock is showing, everything behind it is hidden from VoiceOver. The invisible Skip button on the last onboarding page is hidden too.
- **Swipe to delete** in History is also available from the VoiceOver actions menu.

## Dynamic Type

- All text uses system text styles, so it follows the user's size, including the accessibility sizes.
- Fixed size icons (the logo, the lock, the onboarding pictures, the trust ring and the quick action squares) grow with the text size.
- At accessibility sizes a scan row stacks the risk badge under the text instead of squeezing both side by side, and the address can use three lines.
- The stat cards sit in an adaptive grid, so they wrap onto extra rows rather than clip.

## Colour, contrast and motion

- Risk is never shown by colour alone. A verdict always has an icon and a word, and suspicious wording in a message is underlined as well as red.
- Large controls: category chips have a 44 point touch target.
- **Reduce Motion:** the trust ring appears already full, the icon does not bounce, and the dashboard counters and offline banner do not animate.
- **Reduce Transparency and Increase Contrast** are handled by the system materials and colours used.
- **Haptics** can be switched off in Settings, and are only used for a scan that has just finished.

## How it was checked

- Unit tests cover the spoken text (`AccessibilityTextTests`) and the motion rules (`ResultMotionTests`).
- `AccessibilityAuditTests` runs Apple's automatic accessibility audit on the onboarding and sign in screens.
- Manual checks to repeat before submitting: turn on VoiceOver and scan a link, set Settings, Accessibility, Display & Text Size, Larger Text to the maximum, and turn on Reduce Motion and Increase Contrast.
