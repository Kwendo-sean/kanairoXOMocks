# iOS Home-Screen Widget Setup

This widget shows the user's most recent moment (Locket-style) on the iOS
home screen. The Swift source files are already in this folder — you just
need to wire them into the Xcode project on the Mac.

## One-time setup in Xcode (Mac only)

1. Open `ios/Runner.xcworkspace` in Xcode.
2. **File → New → Target…** → choose **Widget Extension**.
   - Product Name: `KanairoMomentWidget`
   - Include Configuration Intent: **uncheck**
   - Click Finish, **Activate** the scheme when prompted.
3. Xcode creates a new `KanairoMomentWidget` folder with template files.
   Delete the template `.swift` files Xcode generated AND the `Assets.xcassets`
   it added — we'll use the ones already committed in this folder.
4. Right-click the `KanairoMomentWidget` group → **Add Files to "Runner"…**
   → select `KanairoMomentWidget.swift`, `KanairoMomentWidgetBundle.swift`,
   `Info.plist`, and `KanairoMomentWidget.entitlements` from this folder.
   - Make sure they're added to the **KanairoMomentWidget** target only,
     not Runner.
5. Configure the **App Group** capability on BOTH targets:
   - Select Runner target → **Signing & Capabilities** → **+ Capability** →
     **App Groups** → click **+** → add `group.com.kanairoxo.kanairoxo`.
   - Repeat for the `KanairoMomentWidget` target.
6. In Build Settings for the widget target, set:
   - `CODE_SIGN_ENTITLEMENTS` → `KanairoMomentWidget/KanairoMomentWidget.entitlements`
   - `INFOPLIST_FILE` → `KanairoMomentWidget/Info.plist`
   - Deployment target: iOS 16+ (or whatever your Runner targets).
7. Build & run on a device or simulator. Long-press the home screen →
   **+** → search "Latest Moment" → add the widget.

## How it updates

- The Flutter app downloads the latest moment image into the App Group
  container and calls `HomeWidget.updateWidget(...)`.
- The widget extension reads the image path from `UserDefaults(suiteName:)`
  and renders it in a polaroid frame.
- iOS budgets widget refreshes (~15 min minimum), so changes appear within
  a few minutes of being posted in the app.

## What's where

- `KanairoMomentWidget.swift` — TimelineProvider + SwiftUI view (the polaroid)
- `KanairoMomentWidgetBundle.swift` — WidgetBundle entrypoint
- `Info.plist` — extension metadata
- `KanairoMomentWidget.entitlements` — App Group entitlement
