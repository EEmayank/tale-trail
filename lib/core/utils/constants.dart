/// App-wide constants for TaleTrail.
library;

class AppConstants {
  AppConstants._();

  // App info
  static const String appName = 'TaleTrail';
  static const String appTagline = 'Stories that branch';
  static const String appVersion = '1.0.0';
  static const String supportEmail = 'support@taletrail.app';
  static const String privacyPolicyUrl = 'https://taletrail.app/privacy';
  static const String termsUrl = 'https://taletrail.app/terms';
  static const String appStoreUrl =
      'https://apps.apple.com/app/taletrail/id000000000';
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=app.taletrail';

  // Storage keys
  static const String keyHasLaunchedBefore = 'hasLaunchedBefore';
  static const String keyLastActiveProfileId = 'lastActiveProfileId';
  static const String keyLastRemoteConfigFetch = 'lastRemoteConfigFetch';
  static const String keyRecentSearches = 'recentSearches';
  static const String keyBedtimeEnabled = 'bedtimeEnabled';
  static const String keyBedtimeStart = 'bedtimeStart';
  static const String keyBedtimeEnd = 'bedtimeEnd';

  // Firestore collections
  static const String colParents = 'parents';
  static const String colKids = 'kids';
  static const String colStories = 'stories';
  static const String colProgress = 'progress';
  static const String colGamification = 'gamification';
  static const String colSettings = 'settings';

  // Limits
  static const int maxKidProfiles = 6;
  static const int maxKidNameLength = 20;
  static const int minKidAge = 3;
  static const int maxKidAge = 12;
  static const int pinLength = 4;
  static const int maxPinAttempts = 3;
  static const int maxMathAttempts = 3;
  static const int parentalGateTimeoutMinutes = 15;
  static const int maxOfflineStories = 10;
  static const int maxRecentSearches = 10;
  static const int maxConcurrentDownloads = 2;

  // Animations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 600);
  static const Duration splashMinDuration = Duration(seconds: 2);
  static const Duration splashMaxDuration = Duration(seconds: 5);
  static const Duration choiceRevealDelay = Duration(milliseconds: 80);
  static const Duration searchDebounce = Duration(milliseconds: 300);

  // Remote config defaults
  static const bool defaultParallaxEnabled = true;
  static const bool defaultBedtimeModeEnabled = true;
  static const int defaultMaxOfflineStories = 10;
  static const int defaultContentRefreshIntervalHours = 6;
  static const String defaultForceUpdateMinVersion = '1.0.0';
  static const bool defaultMaintenanceMode = false;

  // Avatar IDs
  static const List<String> avatarIds = [
    'avatar_fox',
    'avatar_bear',
    'avatar_panda',
    'avatar_lion',
    'avatar_cow',
    'avatar_frog',
    'avatar_penguin',
    'avatar_unicorn',
    'avatar_tiger',
    'avatar_rabbit',
    'avatar_koala',
    'avatar_wolf',
  ];

  // Avatar emoji map
  static const Map<String, String> avatarEmojis = {
    'avatar_fox': '🦊',
    'avatar_bear': '🐻',
    'avatar_panda': '🐼',
    'avatar_lion': '🦁',
    'avatar_cow': '🐮',
    'avatar_frog': '🐸',
    'avatar_penguin': '🐧',
    'avatar_unicorn': '🦄',
    'avatar_tiger': '🐯',
    'avatar_rabbit': '🐰',
    'avatar_koala': '🐨',
    'avatar_wolf': '🐺',
  };

  // Avatar background colors (index matches avatarIds)
  static const List<int> avatarColors = [
    0xFFD4853A, // fox - desert orange
    0xFF8C7B64, // bear - warm grey
    0xFF4A3F33, // panda - dark
    0xFFC8553D, // lion - terracotta
    0xFF5B8C5A, // cow - sage green
    0xFF4A7C59, // frog - forest green
    0xFF3B7CB8, // penguin - ocean blue
    0xFF6B5BB8, // unicorn - space purple
    0xFFD4853A, // tiger - orange
    0xFFF4E285, // rabbit - warm gold
    0xFF5B8C5A, // koala - sage
    0xFF6B7B8D, // wolf - mountain grey
  ];

  // Story themes
  static const List<String> storyThemes = [
    'forest',
    'space',
    'ocean',
    'animals',
    'folklore',
    'adventure',
  ];

  static const Map<String, String> themeEmojis = {
    'forest': '🌲',
    'space': '🚀',
    'ocean': '🌊',
    'animals': '🐾',
    'folklore': '📖',
    'adventure': '⚔️',
  };

  static const Map<String, String> themeLabels = {
    'forest': 'Forest',
    'space': 'Space',
    'ocean': 'Ocean',
    'animals': 'Animals',
    'folklore': 'Folklore',
    'adventure': 'Adventure',
  };
}
