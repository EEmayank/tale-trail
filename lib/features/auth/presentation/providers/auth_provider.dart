import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Streams the currently signed-in [User], or `null` when signed out.
///
/// This provider wraps [FirebaseAuth.instance.authStateChanges()] so that any
/// widget or provider can reactively respond to authentication state changes.
///
/// Example usage in a widget:
/// ```dart
/// final user = ref.watch(authStateProvider);
/// user.when(
///   data: (u) => u == null ? LoginScreen() : HomeScreen(),
///   loading: () => SplashScreen(),
///   error: (e, _) => ErrorScreen(message: e.toString()),
/// );
/// ```
final authStateProvider = StreamProvider<User?>(
  (ref) => FirebaseAuth.instance.authStateChanges(),
  name: 'authStateProvider',
);
