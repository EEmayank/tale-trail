import 'dart:async';

import 'package:flutter/foundation.dart';

/// A [ChangeNotifier] that calls [notifyListeners] whenever the wrapped
/// [Stream] emits an event.
///
/// Pass an instance of this class to [GoRouter.refreshListenable] to make
/// GoRouter re-evaluate its redirect logic whenever authentication state (or
/// any other stream) changes.
///
/// ```dart
/// GoRouter(
///   refreshListenable: GoRouterRefreshStream(
///     ref.watch(authStateProvider.stream),
///   ),
///   ...
/// )
/// ```
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    // Trigger an immediate evaluation so the router has a baseline state.
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (_) => notifyListeners(),
        );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
