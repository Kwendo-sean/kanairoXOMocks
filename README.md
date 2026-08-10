# KanairoXO

Meet, Connect, Experience — a Nairobi social app for discovering people,
events and places worth going to.

A Flutter app targeting iOS and Android, backed by a Django REST API at
`api.kanairoxo.online`.

---

## Running it

```bash
flutter pub get
flutter run                      # debug, needs the debugger attached
flutter run --release -d <id>    # standalone on a device
```

`flutter devices` lists connected devices and their IDs.

> On iOS, a **debug** build is JIT-compiled and crashes on launch if you open
> it from the home screen without `flutter run` attached. Use `--release` for
> anything you want to keep using, or `--profile` if you need logs from a
> standalone build.

Requires Flutter 3.x (Dart SDK `>=3.0.0 <4.0.0`).

---

## Two experiences

The app splits at `AuthGate` on `account_type`:

- **Singles** — discovery, events, moments, messaging, dates. This is the main
  surface. Documented in **[docs/SINGLES_SECTION.md](docs/SINGLES_SECTION.md)**.
- **Couples** — a separate shell under `lib/screens/couples/`: shared home,
  memories, aspirations, date planning between two linked accounts.

---

## Layout

```
lib/
  auth_gate.dart          Routes splash / onboarding / login / main app
  main.dart               Providers, theme, deep-link wiring
  models/                 API response models
  providers/              ChangeNotifier state (auth, events, profile, theme)
  screens/
    auth/                 Splash, onboarding, login, signup, OTP
    discovery_screen.dart Card deck of recommended people
    events/               Feed, catalogue, filters, detail, tickets
    moments/              Creation flow, detail, my/saved moments
    messaging/            Conversations and chat
    profile/              Profile, editor, gallery
    settings/             Notifications, privacy, blocked, delete
    couples/              The couple experience
    singles/              Profile preview, moment viewer
  services/               API client, auth, notifications, deep links
  widgets/                Shared UI (polaroid stack, cards, toasts)
ios/
  Runner/                 iOS host app, Info.plist, entitlements
  KanairoMomentWidget/    Home-screen widget extension
docs/                     This documentation
```

---

## Things worth knowing before you change anything

**`ApiClient` retries transient failures.** 5xx, 429 and network drops retry
three times with backoff before surfacing anything; auth and 4xx don't. Users
should never see raw exception text — failures resolve to "Sorry, something
went wrong."

**Status messages use `CenterToast`**, not bottom snackbars.

**Brand tokens** are cream `#FAF7F4`, burgundy `#9B111E`, near-black `#1A1A1A`,
dark `#0D0D0D`. Body and UI text is DMSans; the logo is DancingScript.

**iOS signs with a free Apple Developer Personal Team.** Push notifications and
universal links are therefore unavailable — both need entitlements Apple gates
behind the paid programme, and adding those keys fails code signing rather than
enabling the feature. `ios/Runner/Runner.entitlements` documents exactly what
to re-enable on upgrade. `kanairoxo://` custom-scheme deep links do work.

**`record` is pinned to 4.4.4.** Version 5 needs `AudioRecorder`, which
`record_linux` 0.7.2 doesn't implement, and Dart compiles every platform
implementation even for an iOS build.

**`phosphor_flutter` uses a git override** for an unmerged upstream fix — 2.1.0
extends `IconData`, which is now `final` and won't compile.

---

## Backend

`docs/BACKEND_SYNC_REQUIREMENTS.md` lists endpoints the app expects, including
several with UI built but no server support yet — message reactions, unsend,
screenshot alerts, `connections_going` on events. Features degrade quietly
where those are missing rather than erroring.

---

## Branches

`IOS-UPDATES` carries the iOS work and deliberately diverges from `main` in two
places: the For You feed excludes event memories, and the 70% profile-
completion gate on Discover is removed. Merging to `main` carries both to
Android.
