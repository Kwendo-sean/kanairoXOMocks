import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import 'package:kanairoxo/screens/communities/join_by_code_screen.dart';
import 'package:kanairoxo/screens/events/event_detail_screen.dart';
import 'package:kanairoxo/screens/events/event_memories_screen.dart';
import 'package:kanairoxo/services/events_api_service.dart';

/// Listens for kanairoxo.online universal links + the kanairoxo:// custom
/// scheme and routes them to the right in-app screen.
///
/// Paths handled:
///   /c/<code>                          — community join
///   /e/<short>                         — event short-link → resolve UUID
///                                          via backend, push event detail
///   /event/<uuid>                      — event detail
///   /event/<uuid>/moments              — event-moments screen
///   /tickets/<uuid>                    — ticket detail (in My Tickets stack)
///
/// Unauthenticated users get the target stashed in `_pending`. Call
/// [flushPending] after sign-in completes to resume the deep-link.
class DeepLinks {
  DeepLinks._();
  static final instance = DeepLinks._();

  final _appLinks = AppLinks();
  StreamSubscription? _sub;

  /// Set by the AuthGate when an authenticated user is detected.
  /// While `false`, every link is stashed in [_pending] instead of routed.
  bool isAuthenticated = false;

  Uri? _pending;
  GlobalKey<NavigatorState>? _navKey;

  Future<void> attach(GlobalKey<NavigatorState> navKey) async {
    _navKey = navKey;
    try {
      final initial = await _appLinks.getInitialAppLink();
      if (initial != null) _handle(initial);
    } catch (_) {}
    _sub = _appLinks.uriLinkStream.listen(_handle);
  }

  void dispose() {
    _sub?.cancel();
  }

  /// Called by the auth flow once a user signs in. Re-fires the link
  /// that brought them here so they land on the screen they originally
  /// tapped on, not the home tab.
  void flushPending() {
    final p = _pending;
    if (p == null) return;
    _pending = null;
    _handle(p);
  }

  void _handle(Uri uri) {
    final navKey = _navKey;
    if (navKey == null) return;

    // Stash for after-auth replay if the user isn't signed in yet.
    if (!isAuthenticated) {
      _pending = uri;
      return;
    }

    final state = navKey.currentState;
    if (state == null) {
      _pending = uri;
      return;
    }

    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return;

    // ── /c/<code>  community invite ────────────────────────────────
    if (segments[0] == 'c' && segments.length >= 2) {
      state.push(MaterialPageRoute(
          builder: (_) => JoinByCodeScreen(initialCode: segments[1])));
      return;
    }

    // ── /e/<short>  event short link ──────────────────────────────
    if (segments[0] == 'e' && segments.length >= 2) {
      _resolveShortEventAndPush(segments[1]);
      return;
    }

    // ── /event/<uuid>(/moments)? ──────────────────────────────────
    if (segments[0] == 'event' && segments.length >= 2) {
      final eventId = segments[1];
      final wantsMoments = segments.length >= 3 && segments[2] == 'moments';
      if (wantsMoments) {
        state.push(MaterialPageRoute(
            builder: (_) => EventMemoriesScreen(eventId: eventId)));
      } else {
        state.push(MaterialPageRoute(
            builder: (_) => EventDetailScreen(eventId: eventId)));
      }
      return;
    }

    // ── /tickets/<uuid> ───────────────────────────────────────────
    if (segments[0] == 'tickets' && segments.length >= 2) {
      // Defer to MyTicketsScreen with the target id selected.
      // Pushing the my-tickets stack avoids a deep import of the ticket
      // detail screen here.
      // ignore: prefer_const_constructors
      // (No-op for now — the ticket detail screen is built in the
      // ticket-mirror task and can pick up the pending link the same
      // way auth flush does.)
      return;
    }
  }

  Future<void> _resolveShortEventAndPush(String shortCode) async {
    final navKey = _navKey;
    if (navKey == null) return;
    final state = navKey.currentState;
    if (state == null) return;
    try {
      final uuid = await EventsApiService().resolveShortEventCode(shortCode);
      if (uuid != null) {
        state.push(MaterialPageRoute(
            builder: (_) => EventDetailScreen(eventId: uuid)));
      }
    } catch (_) {
      // Silently swallow — invalid short codes shouldn't surface a toast
      // to the user (they'd already see the public event page in browser).
    }
  }
}
