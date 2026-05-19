import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// ParentalGateState
// ---------------------------------------------------------------------------

/// Immutable state for the parental gate feature.
class ParentalGateState {
  const ParentalGateState({
    this.isVerified = false,
    this.verifiedAt,
    this.gateTimeout = const Duration(minutes: 15),
  });

  /// Whether the parent has successfully passed the gate challenge.
  final bool isVerified;

  /// Timestamp of the most recent successful verification.
  final DateTime? verifiedAt;

  /// How long a single verification remains valid before expiring.
  final Duration gateTimeout;

  /// Returns `true` when the last verification is still within [gateTimeout].
  bool get isStillValid {
    if (!isVerified || verifiedAt == null) return false;
    return DateTime.now().difference(verifiedAt!) < gateTimeout;
  }

  ParentalGateState copyWith({
    bool? isVerified,
    DateTime? verifiedAt,
    Duration? gateTimeout,
    bool clearVerifiedAt = false,
  }) {
    return ParentalGateState(
      isVerified: isVerified ?? this.isVerified,
      verifiedAt: clearVerifiedAt ? null : (verifiedAt ?? this.verifiedAt),
      gateTimeout: gateTimeout ?? this.gateTimeout,
    );
  }

  @override
  String toString() =>
      'ParentalGateState(isVerified: $isVerified, verifiedAt: $verifiedAt)';
}

// ---------------------------------------------------------------------------
// ParentalGateStateNotifier
// ---------------------------------------------------------------------------

/// Manages the lifecycle of parental gate verification.
class ParentalGateStateNotifier extends StateNotifier<ParentalGateState> {
  ParentalGateStateNotifier() : super(const ParentalGateState());

  /// Called when the parent successfully completes the gate challenge.
  void verify() {
    state = state.copyWith(
      isVerified: true,
      verifiedAt: DateTime.now(),
    );
  }

  /// Clears verification (e.g. on sign-out or when the timeout is exceeded).
  void revoke() {
    state = state.copyWith(
      isVerified: false,
      clearVerifiedAt: true,
    );
  }

  /// Checks whether the current verification has timed out and revokes it if
  /// so. Call this before granting access to any parent-only route.
  bool checkAndRefresh() {
    if (state.isStillValid) return true;
    if (state.isVerified) {
      // Verification was set but has now expired — clear it.
      revoke();
    }
    return false;
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

/// Global parental gate state.
///
/// Check [ParentalGateState.isStillValid] before rendering parent-only
/// content. If it returns `false`, redirect the user to `/parent-gate`.
final parentalGateStateProvider =
    StateNotifierProvider<ParentalGateStateNotifier, ParentalGateState>(
  (ref) => ParentalGateStateNotifier(),
  name: 'parentalGateStateProvider',
);
