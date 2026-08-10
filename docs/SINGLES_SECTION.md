# The Singles Section

The single-account experience: everything a user sees when `account_type` is
`single`. Couple accounts branch away at the auth gate into a separate shell
and are out of scope here.

This describes what the iOS app does today, on the `IOS-UPDATES` branch. Where
behaviour depends on a backend endpoint that isn't live yet, that's called out
rather than glossed over.

---

## Entry

```
Splash → Onboarding (3 slides) → Login → Main app
                                    ↓
                                 Signup → Main app
```

`AuthGate` (`lib/auth_gate.dart`) decides all of this on every rebuild:

1. Splash while `_splashFinished` is false and nobody is authenticated.
2. `OnboardingScreen` — three slides, shown once per launch for signed-out
   users, tracked by `_onboardingComplete`.
3. `LoginScreen` — email **or** phone, plus Google sign-in. Both routes send
   the identifier as-is; `auth_service` formats it only if it looks like a
   phone number.
4. Signed in, gender unset, and phone empty or a `+2540` placeholder → treated
   as a fresh Google user and sent to `ProfileEditorScreen` before anything
   else.
5. Otherwise → `MainAppScreen`.

Sign-up collects first/last name, email, phone, password, gender and date of
birth. `account_type` is hardcoded to `single` — the couple option was removed
from this flow.

---

## The five tabs

`MainAppScreen` holds a `PageView` behind a liquid-glass nav bar. Re-tapping
the active tab reloads that screen by bumping its `ValueKey`.

| # | Tab | Screen |
|---|----------|-------------------------------------|
| 0 | Discover | `DiscoveryScreen` |
| 1 | Events | `EventsScreen` |
| 2 | Moments | `MomentsScreen` |
| 3 | Messages | `ConversationsScreen` |
| 4 | Profile | `ProfileScreen` |

---

## 1. Discover

A vertical card deck of recommended people from
`GET api/v1/discovery/recommendations/`.

**Actions.** Pass posts to `api/v1/discovery/action/` with `action: 'pass'`.
Connecting goes through `ConnectionService` — either a full request with a
message, or `quickConnect`.

**Looping.** Reaching the end of the deck used to re-initialise, which blanked
the list and could land on the end-of-deck screen even when the server had more
to give. It now wraps back to the first card and refetches quietly behind the
deck, swapping in a new batch only when one actually arrives and never
mid-swipe.

**Empty states — three of them, and the distinction matters:**

- *Genuinely no eligible profiles* → `_ConnectionsFallbackList`, showing your
  existing connections with a "check again" action. A timer re-polls every two
  minutes so the deck recovers on its own.
- *Response we couldn't read* → "We couldn't read today's profiles." This is a
  client-side parse failure, and saying "no one's around" would blame an empty
  city for our bug.
- *Request failed* → the generic error state with a retry.

`DiscoveryBatch.fromJson` accepts `recommendations`, `discoveries`, `profiles`,
`results`, `data` or `items`, and a bare array. Individual malformed rows are
skipped rather than emptying the batch.

**Context cards.** For the top non-ad card, `_loadContextCard` fetches shared
ground — mutual connections, overlapping interests — to show alongside the
profile.

Ads are interleaved as `DiscoveryItem`s with `isAd` set, rendered by `AdCard`.

Tapping through opens `ProfilePreviewScreen`, which also handles inbound
connection requests: arriving with a `connectionId` forces the Accept/Decline
buttons rather than the Save/Connect pair.

---

## 2. Events

Two tabs behind one screen.

### For You — `EventsFeedTab`

A vertical, TikTok-style `PageView` from `api/v1/events/discover-feed/`,
full-bleed video with the CTA in the thumb-zone.

Two card types render here. Event **trailers** ("Get tickets" → event detail)
and date **venues** ("Book this date" → `PlanDateScreen` with the venue
preselected). Event *memories* are filtered out — a deliberate divergence from
Android, where they still appear.

### Events — `EventsScreen`

The browsable catalogue, and the screen with the most structure.

**Header.** A sticky Airbnb-style category strip, derived from whatever
categories the feed actually contains so there's no separate categories
endpoint to keep in sync. Below it, one-tap quick filters — Tonight, This
weekend, Free, Near me — and a `⚙` button opening a sheet for neighbourhood,
price ceiling and "only events my connections are going to."

**Two body modes**, which is the core idea:

- *No filters* → curated horizontal rails (Trending, This Weekend, Happening
  This Week) of tall poster cards, then All Events as wide cards, then past
  events. Rails preview breadth so the sections below stay reachable.
- *Any filter* → rails collapse to a flat counted list — `24 events ·
  Westlands · Free` — with a Clear button. Curation and filtering answer
  different questions, so the screen stops trying to do both.

**Three card sizes**, so six sections don't read as one undifferentiated
scroll: poster (rails), wide (All Events), and compact desaturated rows for
past events, which stay reachable without competing with things still on sale.

**Filtering runs client-side** over the loaded feed (`EventFilters.apply`).
Fine at current scale, but it only filters what's loaded — query params on the
feed endpoint will be needed before the catalogue grows.

**Tickets.** Event detail → tier selection → `TicketPurchaseScreen` →
`TicketsService.purchaseTicket` (or `groupPurchase`) → ticket reveal. Past
events swap "Get tickets" for "View memories".

---

## 3. Moments

Polaroid-styled posts, browsed as a swipeable `PolaroidStack`.

**Creating** is a three-step `PageView` — capture → edit (filters, trim) →
post. The post step takes a caption, location, visibility (Public or
Connections) and an optional linked event. Tag People, Close Friends and Save
Draft were removed; none of them did anything.

Default visibility comes from the "Public moments by default" setting rather
than always starting on Public.

**Viewing.** Tapping a polaroid opens the full-screen original at its own
aspect ratio (`BoxFit.contain` — `cover` was cropping people's photos). Like,
comment, save and share are all on the card; sharing composes a branded
polaroid PNG, or bakes the frame onto video server-side.

**Elsewhere.** `MyMomentsScreen` (archive, delete), `SavedMomentsScreen`, and
`EventMemoriesScreen` for moments tied to an event.

The iOS home-screen widget shows the most recent moment as a polaroid with the
KanairoXO stamp, fed through `HomeWidgetService` into a shared App Group.

---

## 4. Messages

`ConversationsScreen` lists threads; `ChatScreen`
(`lib/screens/messaging/`) is the thread itself. New messages arrive by 3-second
poll plus a push-triggered `newMessageNotifier`.

**Gating.** Every conversation carries `can_send` (`allowed` + `reason`) and
`spark_status` from the server. When sending is blocked the composer disables
itself and shows the server's reason. An expiring spark window surfaces a
banner nudging toward making a plan. A `429` opens the "messaging paused"
dialog.

**Message types.** Text, photo, voice and system.

- *Photos* — multi-select up to 7 with a preview sheet you can deselect from,
  sent at full quality. Tapping a sent photo opens it full-screen with pinch to
  zoom.
- *Voice notes* — tap the mic to start; the input bar becomes a recorder with
  a pulsing dot, live timer, discard and send. Anything under a second is
  thrown away rather than sent as a blip. Recorded as AAC in an m4a container.
- *Long-press* any message for emoji reactions, unsend (your own), or report.

**Screenshots** in a chat notify the other person, wired through a method
channel on `UIApplicationUserDidTakeScreenshotNotification`.

> Reactions, unsend and screenshot alerts need their endpoints server-side
> before they do anything. See `BACKEND_SYNC_REQUIREMENTS.md`.

**Dates** live off this tab: `DatePlannerScreen` (who, when, vibe, where),
`DateRequestsScreen`, `DatePaymentScreen`, `DatesHistoryScreen`. Venue prices
render as real figures — "KSh 2,000 – 5,000 pp" — falling back to the `$`-band
only when `price_min`/`price_max` are missing, since `$$` on a Nairobi venue
reads as US dollars.

---

## 5. Profile

Own profile with completion percentage and next-step prompts, gallery,
interests, tickets, and an entry to Your Moments.

**Editing** covers photo (with 3:4 cropping), bio, headline, neighbourhood,
life stage, social circle and interests. Gallery photos are cropped on upload
and can be long-pressed to delete.

**Settings** (`lib/screens/settings/`):

| Screen | What it does |
|---|---|
| Settings | Account, appearance (system/dark), Moments privacy, entries below |
| Notifications | One on/off switch per category — push and in-app together, email hidden |
| Privacy | Profile visibility, show age, show neighbourhood, message requests, discoverability |
| Blocked | Unblock accounts |
| Delete account | Phone confirmation + reason |

The three Moments toggles — public by default, allow saves, allow shares —
persist locally and mirror to the privacy endpoint. Saves and shares govern
what *other people* may do and can't be enforced from the phone; they need the
matching backend fields to mean anything.

---

## Cross-cutting

**Networking.** `ApiClient` wraps `http` and `dio` behind one interface, with
JWT refresh on 401 and a retry pass — 5xx, 429 and network drops retry three
times with backoff before anything surfaces. Auth and 4xx don't retry. Users
never see raw exception text; failures resolve to "Sorry, something went
wrong."

**Feedback.** `CenterToast` puts status messages in the middle of the screen in
brand burgundy, rather than a bottom snackbar.

**Notifications.** Firebase Messaging with local-notification banners in the
foreground. Routed types: `new_message`, `connection_request`,
`connection_accepted`, `moment_like`, `moment_comment`, `moment_save`,
`drop_reminder`.

> Push does not currently work on iOS. Both `aps-environment` and
> `associated-domains` require a paid Apple Developer membership; this project
> signs with a free Personal Team. `NotificationService` detects the missing
> APNs token and skips device registration quietly. See
> `ios/Runner/Runner.entitlements` for exactly what to re-enable on upgrade.

**Deep links.** `DeepLinks` routes `/c/<code>` (community), `/e/<short>` and
`/event/<uuid>` (events), `/tickets/<uuid>`, and `?claim=<email>`. Links
arriving while signed out are stashed and replayed after sign-in.

> `kanairoxo://` custom-scheme links work. `https://kanairoxo.online/...`
> universal links do not, for the same entitlement reason as push.

**Other surfaces** reachable from the tabs: Communities (browse, create, join
by code), Premium, Notifications, Spotify connect, Recap, Someday/vision board.

---

## Known gaps

| Area | Status |
|---|---|
| Reactions, unsend, screenshot alerts | UI built; endpoints not live |
| `connections_going` on events | UI built; avatar stack hides without it |
| `user_name` on moments | Widget stamp renders nameless without it |
| Moments allow-saves / allow-shares | Local only; needs server enforcement |
| Event filtering | Client-side; needs query params to scale |
| Push notifications | Blocked on paid Apple account |
| Universal links | Blocked on paid Apple account |

`docs/BACKEND_SYNC_REQUIREMENTS.md` has the endpoint-level detail.
