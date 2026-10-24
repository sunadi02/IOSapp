# Multi-device design notes (for the LO1 section of the report)

ScamShield runs on iPhone and iPad. The layout is chosen from the window's horizontal size class, not from the device model, so an iPad in a narrow Split View window behaves like a phone and a large iPhone in landscape can use the wider layout.

| | Compact width (iPhone, narrow iPad window) | Regular width (iPad, wide window) |
|---|---|---|
| Navigation | Tab bar with four tabs: Home, History, Community, Settings | `NavigationSplitView` with a sidebar listing every section |
| Scan screens | Pushed from Home | Their own sidebar entries: Check a Link, Scan QR Code, Scan a Screenshot |
| History | List, tap pushes the result | List on the left, the chosen result on the right |
| Input | Touch | Touch, trackpad hover effects, keyboard shortcuts, drag and drop |

## Why these choices

- **Sidebar on iPad.** A tab bar with seven items would be crowded and hides the scan tools two taps deep. A sidebar uses the width, keeps every section one tap away, and matches how iPadOS apps such as Mail and Notes work.
- **Master detail in History.** Reading why a link was rated Risky is the main reason to open history. Showing the result beside the list lets a person compare several scans without going back and forth.
- **One selection shared by both layouts.** The chosen section is held above both layouts, so rotating an iPad or resizing its window switches between the sidebar and the tab bar without losing the place. The three scan screens map to the Home tab on a phone, because that is where they live there.
- **Sensible content width.** The dashboard and sign-in forms keep a maximum width so lines do not stretch across a 13 inch screen.

## iPad specific features

- Keyboard shortcuts (hold the Command key to see them): Command 1 Home, Command L Check a Link, Shift Command Q Scan QR Code, Shift Command S Scan a Screenshot, Command 2 History, Command F Find in History, Command 3 Community, Command comma Settings.
- Drag an image from Photos or Files onto the screenshot scanner or the QR scanner. Only images are accepted, so dragging text onto the message box still just pastes the text.
- Pointer hover effects on the quick action cards, recent scans and category chips.

## Limits

- The keyboard shortcuts only apply in the sidebar layout. On a phone the scan screens open from Home, so there is nothing for them to jump to.
- The in-app camera scanner needs a real device camera. In the simulator the Scan from Photo option or a dropped image is used instead.
