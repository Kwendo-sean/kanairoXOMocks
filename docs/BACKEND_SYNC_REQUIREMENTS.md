# Backend sync — what the app needs to catch up on

Generated 2026-08-07 after a large backend session. Everything below is
**already live on the API**; this is the Flutter work needed to use it.

Ground rule that still holds: **roll the backend out before shipping the
Flutter change that depends on it.** The reverse breaks users on older
builds.

---

## P0 — do these first

### 1. Event status is now clock-aware (`display_status`)

`status` alone reported `live` forever — nothing moved a finished event
off it, so past events advertised themselves as live everywhere.

Both event serializers now expose:

| Field | Type | Meaning |
|---|---|---|
| `display_status` | string | `live` / `ongoing` / `completed` / `draft` / `cancelled` / `pending_approval` |
| `is_past` | bool | event has ended |

**Change required:** render badges and filters from `display_status`, not
`status`. `ongoing` should read "happening now"; `completed` should read
"past". `cancelled` and `draft` always win over the clock — a cancelled
event that has since passed is still cancelled.

Affected: `event_card.dart`, `event_detail_screen.dart`, the events feed
tab, and anywhere "You attended" is computed.

### 2. Ticket purchase actually works now — retest it

Two model bugs were fixed that broke **app purchases**, not just web:

* `EventAttendee.save()` used `self.pk is None` to detect a new row, but
  the pk is a UUID with a default and is never None — so every
  first-time attendee raised `DoesNotExist`.
* It then assigned an `F()` expression to the in-memory Event, which
  `Event.save()` compared against `max_capacity` → `TypeError`.

Together: **buying a ticket for an event you hadn't already registered
for failed.** Retest the whole in-app purchase flow end to end. No
Flutter change expected — but this path has likely never worked in
production, so treat it as untested.

### 3. Quantity issues N tickets, not one

Buying 3 used to create ONE ticket row carrying the full total, so two
of the three people had no QR. The API now returns:

```json
{ "ticket_id": "…", "ticket_ids": ["…","…","…"], "quantity": 3 }
```

**Change required:** if the app offers quantity, show all returned
tickets (each has its own QR), not just the first. Check
`ticket_purchase_screen.dart` and `my_tickets`.

---

## P1 — new capability to expose

### 4. Claim-account flow (guest buyers)

The web now sells tickets without an account. Doing so creates a
**passwordless** user keyed on the buyer's email and emails them an
invite to claim it, linking to:

```
https://app.kanairoxo.online/?claim=<email>
```

**Change required:** handle that deep link. Route to a "set your
password" screen that uses the existing reset endpoints:

* `POST /api/v1/auth/password/reset/request/` `{identifier}` → emails a 6-digit code
* `POST /api/v1/auth/password/reset/confirm/` `{identifier, code, new_password}`

On success the user signs in and **their guest tickets are already
attached** — same email, same account. This is the main funnel from a
shared web link into the app; it deserves a proper screen, not a
browser hand-off.

### 5. Login accepts email or phone

`POST /api/v1/auth/login/` now takes `identifier` (email **or** phone)
alongside the legacy `phone_number`. App users still sign up by phone —
that stays the anti-spam gate — but a guest who claimed their account
may only know their email.

**Change required (small):** send `identifier` instead of
`phone_number`, and relabel the field "Email or phone". The old key
still works, so this is not urgent.

### 6. Card payments (Paystack)

The web offers M-Pesa **and** card. The app is M-Pesa only.

`POST /api/v1/tickets/guest-purchase/<event_id>/` accepts
`payment_method: "card"` and returns `authorization_url` to open in a
web view. Worth adding for diaspora and corporate buyers, and for anyone
out of M-Pesa float. Not blocking.

---

## P2 — nice to have

### 7. Per-ticket attendee names

Group purchases can now name each ticket, and optionally send each one
to its own email:

```json
"attendees": [
  {"name": "Ada"},
  {"name": "Grace", "email": "grace@example.com"}
]
```

Name only → issued in their name, delivered to the buyer. With an email
→ goes straight to them. Send `[]` (never `null`) when there's nothing
to add.

### 8. Universal links moved to `app.kanairoxo.online`

`apple-app-site-association` and `assetlinks.json` are served from
`app.kanairoxo.online`, and the web "Get ticket" CTA points there.

**Change required:** the iOS associated-domains entitlement and the
Android intent-filter must list `app.kanairoxo.online`. Until the app is
published these links land on a "this lives in the app" hub page, which
is the correct fallback.

Still blocked on the Apple developer licence:
`APP_APPLE_TEAM_ID`, `APP_APPLE_BUNDLE_ID`,
`APP_ANDROID_PACKAGE_NAME`, `APP_ANDROID_SHA256_FINGERPRINT`. The
`.well-known` endpoints 404 by design until all four are set — deliberate,
so we never claim links the app can't handle.

---

## Already shipped in this repo (no action)

* Video moments export as video — baked polaroid mp4 + raw clip
* Event share defaults to the trailer when one exists
* Discover empty state auto-recovers instead of dead-ending
* Moment export preview authenticated (was 401ing silently)
* Event link picker fixed (was always empty — parsed UUIDs as ints)

**Needs an APK rebuild to reach devices:** all of the above are committed
but only reach users on the next build.

---

## Open questions for the backend

1. Should the app offer guest checkout too (buy before signup), or keep
   requiring an account in-app? Web conversion argues for guest.
2. Do we want push notifications on ticket confirmation? The FCM call
   was importing a function that doesn't exist and silently failed —
   fixed backend-side, so pushes will start arriving once devices
   register tokens.
