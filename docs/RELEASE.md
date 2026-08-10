# Shipping KanairoXO

How to get the app onto the App Store and Play Store, and how to make
`https://kanairoxo.online/...` links open the app instead of Safari or Chrome.

Written against the state of the repo on 2026-08-10. Where something is not yet
done, it says so rather than pretending.

---

## 1. Where we actually are

| | iOS | Android |
|---|---|---|
| Bundle / package | `com.kanairoxo.app` | `com.example.kanairoxo` ⚠️ |
| Firebase app | registered | registered |
| Signing | **free personal team** ⚠️ | debug keystore only ⚠️ |
| Push notifications | **off** (needs paid membership) | works |
| Universal / app links | **off** (needs paid membership) | manifest ready, backend not configured |
| Home-screen widget | working | working |

Three things block a store release. None are hard; all take longer than you'd
think because of propagation and review.

**A. The Android package is `com.example.kanairoxo`.** Google Play rejects
anything starting `com.example`. It has to change *before* the first upload —
a package name is permanent once published, so there is no fixing it later.

**B. iOS is on a free Apple Developer account.** Push notifications and
universal links are both paid-tier capabilities. Adding the entitlement keys
on a free team fails code signing rather than enabling the feature — see the
comment block in `ios/Runner/Runner.entitlements`, which explains this in
detail.

**C. Both apps are signed with development keys.** Release builds use
different certificates, and anything keyed to a certificate fingerprint
(Google sign-in, Android app links) silently breaks unless the release
fingerprints are registered too. This is the one that passes every test and
then fails for real users on day one.

---

## 2. Pre-flight

### 2.1 Rename the Android package

Pick one and use it everywhere. `com.kanairoxo.app` matches iOS, which keeps
things simple.

1. `android/app/build.gradle.kts` — change both `namespace` and
   `applicationId`.
2. Move the Kotlin sources:
   `android/app/src/main/kotlin/com/example/kanairoxo/` →
   `android/app/src/main/kotlin/com/kanairoxo/app/`, and update the `package`
   line at the top of `MainActivity.kt`, `MomentsWidgetProvider.kt`,
   `ActivityWidgetProvider.kt`, `DropWidgetProvider.kt`.
3. Firebase Console → Project Settings → **Add app** → Android, with the new
   package. (Add a new app; don't try to edit the old one — the package is
   immutable there too.)
4. Download the fresh `google-services.json` into `android/app/`.
5. Re-register the SHA-1 fingerprints (§2.3).
6. `flutter clean && flutter build apk --debug` and confirm Google sign-in
   still works before going further.

### 2.2 Apple Developer Program

$99/yr, and enrolment can take a day or two — start it before you need it.

Once active:

1. Apple Developer portal → Identifiers → your App ID → enable **Push
   Notifications** and **Associated Domains**.
2. Put the entitlement keys back into `ios/Runner/Runner.entitlements`. The
   exact block to paste is already in the comment there. Use
   `aps-environment` = `development` for local, `production` for
   TestFlight/App Store.
3. Create an **APNs auth key** (.p8) and upload it to Firebase Console →
   Project Settings → Cloud Messaging. Without this, FCM cannot deliver to
   iOS *even with the entitlement present* — the token exists but nothing
   arrives.

### 2.3 Signing keys, and the fingerprints that follow them

**Android.** Create an upload keystore and keep it somewhere you will still
have in two years — losing it means you cannot update your own app.

```bash
keytool -genkey -v -keystore ~/kanairoxo-upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Reference it from `android/key.properties` (git-ignored) and wire it into
`android/app/build.gradle.kts` signing config.

Then register **three** SHA-1 fingerprints in Firebase, not one:

| Which | Where it comes from | Needed for |
|---|---|---|
| Debug | `~/.android/debug.keystore` | local dev — already registered |
| Upload | the keystore you just made | internal testing tracks |
| **Play App Signing** | Play Console → Setup → App signing | **every real user** |

That third one is the one people miss. Google re-signs your upload with their
own key, so the certificate on a user's phone is not the one you signed with.
Google sign-in fails for everyone in production while working perfectly in
testing.

```bash
# SHA-1 and SHA-256 of any keystore
keytool -list -v -keystore <path> -alias <alias>
```

Keep the **SHA-256** of the Play App Signing key too — §3 needs it.

**iOS.** Xcode → Signing & Capabilities → automatic signing with your paid
team handles this. Just confirm the bundle ID is `com.kanairoxo.app` and the
app group `group.com.kanairoxo.kanairoxo` is present, or the widget breaks.

---

## 3. Deep links

### How it works

A universal link is a normal `https://` URL that the OS routes to the app
instead of the browser — but only if the OS can verify the app is allowed to
claim that domain. Verification is a file served from the domain.

The backend already serves both files:

```
https://kanairoxo.online/.well-known/apple-app-site-association
https://kanairoxo.online/.well-known/assetlinks.json
```

They are generated from env vars, and **return 404 until those are set** —
deliberately, so we never claim links the app cannot handle.

Claimed paths (`apps/events/well_known.py`):

```
/event/*/moments      the in-app event memories screen
/event/*              event detail
/e/*                  short share links
/tickets/*            a purchased ticket
```

### What to set

On the server `.env`, then restart web:

```bash
APP_APPLE_TEAM_ID=<10-char Team ID from developer.apple.com → Membership>
APP_APPLE_BUNDLE_ID=com.kanairoxo.app
APP_ANDROID_PACKAGE_NAME=com.kanairoxo.app
APP_ANDROID_SHA256_FINGERPRINT=<SHA-256 of the PLAY APP SIGNING key>
```

Note the last one: it must be the fingerprint of the certificate **as
installed on a user's device**. For a Play-distributed app that is the Play
App Signing key, not your upload key. Get it wrong and links open the browser
with no error message anywhere.

### The subdomain trap

`ios/Runner/Runner.entitlements` claims **two** domains:

```
applinks:kanairoxo.online
applinks:app.kanairoxo.online
```

iOS fetches the association file from **each** domain independently. The
backend currently serves it from the root domain only, so
`app.kanairoxo.online` must either serve the same file or be dropped from the
entitlement. Whichever you choose, do it before submitting — iOS caches the
result and a failed fetch is not retried promptly.

### Android manifest

Already correct — `android/app/src/main/AndroidManifest.xml` has an
`autoVerify="true"` intent filter for `https://kanairoxo.online`. After the
package rename, nothing here changes.

### Verifying it actually works

Do this **before** submitting, not after.

```bash
# Both must return 200, JSON, and no redirect
curl -sI https://kanairoxo.online/.well-known/apple-app-site-association
curl -s  https://kanairoxo.online/.well-known/assetlinks.json | jq .
```

A redirect (even http→https) breaks Apple's fetch. Cloudflare must not be
transforming or caching these to something else.

```bash
# Android: does the OS accept our claim?
adb shell pm get-app-links com.kanairoxo.app
# want: kanairoxo.online: verified

# force re-verification after a change
adb shell pm verify-app-links --re-verify com.kanairoxo.app
```

```bash
# Fire a real link at a device
adb shell am start -a android.intent.action.VIEW \
  -d "https://kanairoxo.online/event/<uuid>" com.kanairoxo.app
```

On iOS, paste the link into Notes and long-press it — Safari's address bar
deliberately does not trigger universal links, which is the single most
common reason people think theirs are broken.

Apple's CDN caches the association file for up to 24h. If you change it,
expect a wait, or delete and reinstall the app to force a fresh fetch.

---

## 4. iOS release

```bash
flutter build ipa --release
```

1. Xcode → Product → Archive, or upload `build/ios/ipa/*.ipa` via Transporter.
2. App Store Connect → TestFlight. Internal testing needs no review; external
   testers need a short one.
3. Install from TestFlight and check the list in §6.
4. App Store Connect → submit for review.

**Before you submit:**

- `aps-environment` is `production`, not `development` — this is the most
  common cause of "push worked in TestFlight and died on launch"
- Privacy nutrition labels declare what we collect: email, phone, photos,
  location strings, contacts if used
- A demo account for the reviewer, verified and with an event and a
  connection already on it. Reviewers reject accounts that dead-end at an
  OTP screen they cannot receive
- Review takes 24–48h typically, longer on a first submission

### Apple will ask about

- **Account deletion.** Required. We have it —
  `DELETE /api/v1/auth/me/delete/`, reachable from Settings. Tell them where.
- **Sign in with Apple.** If you offer Google sign-in, Apple require theirs
  too. **We do not have it.** This is a hard rejection and it is not yet
  built — either add it or drop Google sign-in from the iOS build.
- **UGC moderation.** Moments and chat are user content, so they expect
  reporting, blocking, and a stated response window. We have reporting and
  blocking; point at them explicitly.

---

## 5. Android release

```bash
flutter build appbundle --release   # .aab, not .apk — Play wants a bundle
```

1. Play Console → create the app → upload `build/app/outputs/bundle/release/app-release.aab`
2. **Enrol in Play App Signing** (default). Then collect the SHA-1 and SHA-256
   it generates and register both (§2.3, §3) — this is the step whose absence
   breaks sign-in and deep links for real users only.
3. Internal testing track first. It reaches testers in minutes.
4. Fill in the Data Safety form — it must match what the app actually does or
   it is rejected on review.
5. Promote to production.

First review is typically a few days; later updates are faster.

---

## 6. Post-install checklist

Run on a real device from a store build, not a debug build. Half of these
only fail in release.

**Auth**
- [ ] Sign up → OTP email arrives → code verifies → lands in the app
- [ ] Forgot password → code arrives → new password → signed in automatically
- [ ] Google sign-in (**the fingerprint check** — fails only in release)
- [ ] Kill and reopen on the OTP screen; it must still be there

**Deep links**
- [ ] `https://kanairoxo.online/event/<id>` opens the app, not the browser
- [ ] `/e/<code>` short link
- [ ] `/tickets/<id>?tk=...` opens the ticket
- [ ] Same link with the app **not** running — cold start is a separate path
- [ ] From Notes/WhatsApp, not the browser address bar

**Push**
- [ ] Device token registers after login (`/api/v1/accounts/device/register/`)
- [ ] A message notification arrives with the app backgrounded
- [ ] Tapping it opens the right conversation

**Money**
- [ ] Buy a ticket end to end with real M-Pesa
- [ ] Ticket email arrives with the PDF
- [ ] Partner sees the sale in their dashboard
- [ ] The revenue row appears in admin payouts

**The rest**
- [ ] Photo and voice note in chat
- [ ] Video plays in the events feed
- [ ] Home-screen widget shows the latest moment
- [ ] Account deletion works — Apple will test this

---

## 7. Things that will bite

**A package name is forever.** `com.example.kanairoxo` cannot go to Play, and
whatever replaces it cannot be changed after the first publish.

**Play App Signing changes your certificate.** Everything keyed to a
fingerprint — Google sign-in, app links — needs Google's fingerprint, not
yours. Symptom: works perfectly in testing, broken for every real user.

**Apple caches the association file** for up to 24h. Get it right before
submitting rather than iterating after.

**`aps-environment` must be `production`** for anything leaving your machine.

**Sign in with Apple is missing.** If Google sign-in ships on iOS, Apple
require Sign in with Apple alongside it. Currently unbuilt — decide before
submission, not during review.

**The reviewer needs an account that works.** Ours gates on email
verification, so a demo account must be pre-verified or the reviewer cannot
get past the first screen. That is an automatic rejection and costs a full
review cycle.
