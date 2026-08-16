# App changes needed after the backend work (Aug 2026)

Written against the app as it stands today, after reading `lib/`. The backend
is deployed; these are the gaps on this side.

Ordered by what breaks for a user, not by effort.

---

## P0 — the "View online" button is broken

**`lib/features/tickets/screens/ticket_reveal_screen.dart:441`**

```dart
onPressed: () => _launchUrl("${ApiConstants.baseUrl}/tickets/${ticket.id}/"),
```

Two faults in one line:

1. **No `?tk=` token.** The ticket page is no longer AllowAny. Without the
   signed token it redirects to the public *event* page — which is exactly the
   "it takes me to the events page" bug.
2. **Wrong host.** `ApiConstants.baseUrl` is `api.kanairoxo.online`; ticket
   pages live on `tickets.kanairoxo.online`.

`url_launcher` opens the system browser, which sends neither a session cookie
nor the JWT — so nothing the app does at request time can rescue an unsigned
URL. The token has to be *in* the link.

**Fix:** use the `view_url` field the API now returns.

```dart
final url = ticket.viewUrl;          // add to TicketModel
if (url != null && url.isNotEmpty) _launchUrl(url);
```

`GET /api/v1/tickets/` returns `view_url` per ticket, already signed and
pointed at the right host. Never build this URL in the app again — the token
now expires and is invalidated by transfers, so a hand-built one cannot work.

**Also add `view_url` to both ticket models** — `lib/models/ticket_model.dart`
and `lib/features/tickets/models/ticket_model.dart` (there are two).

---

## P1 — refunds have no UI at all

The endpoints are live and tested; nothing calls them. Right now a buyer's only
route is emailing support, and the refund policy page tells them to use an
in-app button that does not exist.

**On the ticket screen**, gated on eligibility:

```
GET  /api/v1/tickets/<id>/refund-status/
     → { policy, policy_text, eligible, reason, refund }

POST /api/v1/tickets/<id>/refund-request/   { reason }
     → 201 { refund_id, status, amount, currency, detail }
     → 400 { detail }  — ineligible, and `detail` is written to be shown
     → 409 { detail }  — one already in progress
```

Show `policy_text` on the ticket regardless (e.g. *"Full refund if you cancel
more than 48 hours before"*). Show the button only when `eligible` is true —
a button that always 400s is worse than none. When `refund` is non-null, show
its status instead of the button.

`detail` on a 400 is human-readable and specific ("This ticket has already been
used at the door") — surface it verbatim rather than a generic failure.

**Date bookings** have the same pair under
`/api/v1/dates/receipts/<receipt_id>/refund-request/` and `/refund-status/`.

---

## P1 — show the refund rule before payment

`GET /api/v1/events/<id>/` now returns `refund_policy` and
`refund_policy_text`. The web checkout shows this immediately above the pay
button, and the app should too.

This matters legally, not cosmetically: the rule a buyer was shown before
paying is the one we are held to. The event list serializer carries the same
two fields, so the ticket-purchase screen needs no extra request.

---

## P2 — sold-out now returns 409

The backend enforces venue capacity at purchase for the first time. Previously
only per-tier caps were checked, so an event could sell past the room it was
held in.

`POST /api/v1/tickets/purchase/<event_id>/` can now return:

```
409 { "detail": "Only 2 place(s) left for this event." }
409 { "detail": "This event is sold out." }
409 { "detail": "Only 3 Early Bird tickets left." }   // tier cap, pre-existing
```

`lib/screens/events/ticket_purchase_screen.dart` has no 409 branch. Show
`detail` and let them lower the quantity — the message already names the number
available.

---

## P2 — general admission is now a real option

The event page previously listed only named tiers, so when they all sold out
there was nothing to select while the total silently fell back to the event's
`base_price`.

The public web page now lists **General admission** as a selectable option with
an **empty `id`** — meaning "send no `pricing_tier_id`". If the app builds its
own tier list from `pricing_tiers`, it needs the same fallback row whenever
`base_price > 0` and no tier matches that price. Sending `pricing_tier_id: null`
is what selects it.

---

## P2 — payment provider changed underneath you

M-Pesa can now run through **Paystack** instead of Daraja, chosen by a server
env var. The purchase response is deliberately shape-compatible —
`checkout_request_id` is still there, polling still works — so **no app change
is required**.

One addition worth reading: the response now carries `"provider": "paystack" |
"daraja"`. Useful only for support ("which rail did this go through?").

The `authorization_url` card flow is unchanged.

---

## P3 — gifting is wired end to end on the backend

`attendees` already posts correctly from `ticket_purchase_screen.dart`. Two
upgrades now available:

- Each recipient entry accepts **`user_id`** as well as `name`/`email`. Passing
  a connection's id binds the ticket to their account, so it appears in *their*
  My Tickets and they get a push — an email-only recipient gets neither.
  `invite_friends_screen.dart` already collects recipients; adding a connection
  picker is the natural place.
- A recipient entry accepts **`message`**, which appears in the gift email
  ("*X got you a ticket*" plus their note). Currently collected nowhere.

Also: `GET /api/v1/tickets/` now includes tickets **gifted to** the signed-in
user, not just ones they bought. No change needed — just be aware My Tickets
may show tickets the user never paid for.

---

## P3 — media URLs moved host

Uploads are served from `media.kanairoxo.online` rather than the API host, and
**private files** (message attachments, voice notes, ticket PDFs) are now
signed URLs that **expire after 12 hours**.

Anything the app caches long-term by URL will start 404ing or returning
`410 Link expired`. Cache the *object*, re-fetch to get a fresh URL — do not
persist a media URL and reuse it days later.

---

## Quick reference — new/changed response fields

| Endpoint | New field | Use |
|---|---|---|
| `GET /api/v1/tickets/` | `view_url` | **Use instead of building the URL** |
| `GET /api/v1/tickets/<id>/refund-status/` | all | Eligibility + policy |
| `GET /api/v1/events/<id>/` | `refund_policy`, `refund_policy_text` | Show before payment |
| `POST .../purchase/` | `provider`, `order_ref`, `quantity` | `ticket_ids` already handled |
| `POST .../purchase/` | 409 responses | Capacity — needs handling |

---

## Not app work, but worth knowing

- **Receipts.** Buyers now get a separate receipt email (amount, M-Pesa code,
  commission-free breakdown) alongside the ticket. Nothing to build.
- **Payout dates and the partner guide** are partner-panel only.
- **The ticket QR is still static** — a screenshot is a working ticket until
  scanned. Rotating in-app codes are the next security tier and would be
  substantial app work; see `docs/TICKETING_FIXES_AND_SECURITY.md` in the
  backend repo before starting that.
