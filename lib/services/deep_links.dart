import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import 'package:kanairoxo/screens/communities/join_by_code_screen.dart';

/// Listens for `https://kanairoxo.online/c/<code>` (or `/c/<code>` on any
/// configured host). Opens the Join screen with the code pre-filled.
class DeepLinks {
  DeepLinks._();
  static final instance = DeepLinks._();

  final _appLinks = AppLinks();
  StreamSubscription? _sub;

  Future<void> attach(GlobalKey<NavigatorState> navKey) async {
    try {
      final initial = await _appLinks.getInitialAppLink();
      if (initial != null) _handle(initial, navKey);
    } catch (_) {}
    _sub = _appLinks.uriLinkStream.listen((uri) => _handle(uri, navKey));
  }

  void dispose() {
    _sub?.cancel();
  }

  void _handle(Uri uri, GlobalKey<NavigatorState> navKey) {
    final segments = uri.pathSegments;
    if (segments.length >= 2 && segments[0] == 'c') {
      final code = segments[1];
      final state = navKey.currentState;
      if (state == null) return;
      state.push(MaterialPageRoute(
        builder: (_) => JoinByCodeScreen(initialCode: code)));
    }
  }
}
