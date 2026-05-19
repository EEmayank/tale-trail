import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kids_stories/features/auth/domain/entities/kid_profile.dart';

/// Holds the currently active [KidProfile].
///
/// Starts as `null` (no profile selected). Set this provider's state after the
/// user selects a profile from [KidProfileSelectorScreen] or after
/// [AppInitializer] restores the last active profile from persistent storage.
///
/// Example:
/// ```dart
/// // Select a profile:
/// ref.read(activeKidProfileProvider.notifier).state = selectedProfile;
///
/// // Clear on sign-out:
/// ref.read(activeKidProfileProvider.notifier).state = null;
/// ```
final activeKidProfileProvider = StateProvider<KidProfile?>(
  (ref) => null,
  name: 'activeKidProfileProvider',
);
