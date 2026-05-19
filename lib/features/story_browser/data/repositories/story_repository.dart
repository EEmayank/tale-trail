import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kids_stories/features/story_browser/data/models/story_summary.dart';

// ---------------------------------------------------------------------------
// Mock data
// ---------------------------------------------------------------------------

final List<StorySummary> _mockStories = [
  const StorySummary(
    id: 'story_clever_fox',
    title: 'The Clever Fox',
    coverUrl: '',
    description:
        'Deep in the enchanted forest lives a fox whose wit is sharper than any blade. '
        'When the animals need help solving a great riddle, only the clever fox can lead them.',
    ageMin: 4,
    ageMax: 8,
    themes: ['forest', 'animals'],
    isFree: true,
    isPremium: false,
    durationMinutes: 10,
    language: 'en',
    endingCount: 3,
    isNew: true,
    isPopular: true,
    colorAccent: '#4A7C59',
  ),
  const StorySummary(
    id: 'story_raja_stars',
    title: 'Raja and the Stars',
    coverUrl: '',
    description:
        'Young Raja discovers a mysterious telescope on his rooftop that can reach the stars. '
        'A space odyssey full of wonder, friendship, and the courage to explore the unknown.',
    ageMin: 6,
    ageMax: 10,
    themes: ['space'],
    isFree: false,
    isPremium: true,
    durationMinutes: 15,
    language: 'en',
    endingCount: 4,
    isNew: true,
    isPopular: false,
    colorAccent: '#6B5BB8',
  ),
  const StorySummary(
    id: 'story_ocean_dream',
    title: 'The Ocean Dream',
    coverUrl: '',
    description:
        'Mira falls asleep on the beach and wakes up beneath the waves. '
        'She must find her way home through coral castles and talking dolphins.',
    ageMin: 4,
    ageMax: 7,
    themes: ['ocean'],
    isFree: true,
    isPremium: false,
    durationMinutes: 8,
    language: 'en',
    endingCount: 2,
    isNew: false,
    isPopular: true,
    colorAccent: '#3B7CB8',
  ),
  const StorySummary(
    id: 'story_tenali_plan',
    title: "Tenali's Clever Plan",
    coverUrl: '',
    description:
        "Tenali Rama must outsmart the royal court's trickiest puzzle to save the kingdom's greatest treasure. "
        'A beloved tale from Indian folklore reimagined with new choices.',
    ageMin: 6,
    ageMax: 10,
    themes: ['folklore'],
    isFree: true,
    isPremium: false,
    durationMinutes: 12,
    language: 'en',
    endingCount: 3,
    isNew: false,
    isPopular: true,
    colorAccent: '#D4853A',
  ),
  const StorySummary(
    id: 'story_magic_forest',
    title: 'The Magic Forest',
    coverUrl: '',
    description:
        'In a forest where trees can speak and flowers sing, little Anya discovers a hidden door '
        'that leads to the heart of all magic.',
    ageMin: 3,
    ageMax: 6,
    themes: ['forest', 'animals'],
    isFree: true,
    isPremium: false,
    durationMinutes: 6,
    language: 'en',
    endingCount: 2,
    isNew: false,
    isPopular: false,
    colorAccent: '#4A7C59',
  ),
  const StorySummary(
    id: 'story_moon_journey',
    title: 'Journey to the Moon',
    coverUrl: '',
    description:
        'A daring crew of young astronauts launch on the adventure of a lifetime. '
        'But when their rocket goes off-course, they must rely on each other to find their way home.',
    ageMin: 7,
    ageMax: 12,
    themes: ['space', 'adventure'],
    isFree: false,
    isPremium: true,
    durationMinutes: 20,
    language: 'en',
    endingCount: 5,
    isNew: true,
    isPopular: true,
    colorAccent: '#6B5BB8',
  ),
];

// ---------------------------------------------------------------------------
// StoryRepository
// ---------------------------------------------------------------------------

/// Fetches and filters stories from Firestore, falling back to mock data on
/// any error.
class StoryRepository {
  StoryRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _storiesRef =>
      _firestore.collection('stories');

  // ---------------------------------------------------------------------------
  // fetchStories
  // ---------------------------------------------------------------------------

  Future<List<StorySummary>> fetchStories({
    String? theme,
    int? ageMin,
    int? ageMax,
    String? language,
    bool? isFree,
    int page = 0,
    int limit = 20,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _storiesRef;

      if (language != null) {
        query = query.where('language', isEqualTo: language);
      }
      if (isFree != null) {
        query = query.where('isFree', isEqualTo: isFree);
      }
      if (ageMin != null) {
        query = query.where('ageMax', isGreaterThanOrEqualTo: ageMin);
      }
      if (ageMax != null) {
        query = query.where('ageMin', isLessThanOrEqualTo: ageMax);
      }

      query = query.limit(limit);

      final snapshot = await query.get();
      var results = snapshot.docs
          .map((doc) => StorySummary.fromFirestore(doc))
          .toList();

      // Theme filter applied in-memory (Firestore array-contains for single theme).
      if (theme != null && theme != 'all') {
        results =
            results.where((s) => s.themes.contains(theme)).toList();
      }

      return results.isEmpty ? _filterMock(theme: theme, ageMin: ageMin, ageMax: ageMax, isFree: isFree) : results;
    } catch (_) {
      return _filterMock(theme: theme, ageMin: ageMin, ageMax: ageMax, isFree: isFree);
    }
  }

  List<StorySummary> _filterMock({
    String? theme,
    int? ageMin,
    int? ageMax,
    bool? isFree,
  }) {
    return _mockStories.where((s) {
      if (theme != null && theme != 'all' && !s.themes.contains(theme)) {
        return false;
      }
      if (ageMin != null && s.ageMax < ageMin) return false;
      if (ageMax != null && s.ageMin > ageMax) return false;
      if (isFree != null && s.isFree != isFree) return false;
      return true;
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // searchStories
  // ---------------------------------------------------------------------------

  Future<List<StorySummary>> searchStories(String query) async {
    if (query.trim().isEmpty) return [];
    final lower = query.toLowerCase();
    try {
      // Firestore doesn't support full-text search natively; do a prefix match
      // on the title field and fall back to in-memory filtering of mock data.
      final snapshot = await _storiesRef
          .orderBy('title')
          .startAt([lower])
          .endAt(['$lower\uf8ff'])
          .limit(20)
          .get();

      final results =
          snapshot.docs.map((d) => StorySummary.fromFirestore(d)).toList();

      return results.isEmpty ? _searchMock(lower) : results;
    } catch (_) {
      return _searchMock(lower);
    }
  }

  List<StorySummary> _searchMock(String lower) {
    return _mockStories
        .where((s) =>
            s.title.toLowerCase().contains(lower) ||
            s.description.toLowerCase().contains(lower) ||
            s.themes.any((t) => t.contains(lower)))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // getFeaturedStories
  // ---------------------------------------------------------------------------

  Future<List<StorySummary>> getFeaturedStories() async {
    try {
      final snap = await _storiesRef
          .where('isPopular', isEqualTo: true)
          .limit(6)
          .get();
      final results =
          snap.docs.map((d) => StorySummary.fromFirestore(d)).toList();
      return results.isEmpty
          ? _mockStories.where((s) => s.isPopular).toList()
          : results;
    } catch (_) {
      return _mockStories.where((s) => s.isPopular).toList();
    }
  }

  // ---------------------------------------------------------------------------
  // getStoriesForKid
  // ---------------------------------------------------------------------------

  Future<List<StorySummary>> getStoriesForKid(int age) async {
    try {
      final snap = await _storiesRef
          .where('ageMin', isLessThanOrEqualTo: age)
          .where('ageMax', isGreaterThanOrEqualTo: age)
          .limit(20)
          .get();
      final results =
          snap.docs.map((d) => StorySummary.fromFirestore(d)).toList();
      return results.isEmpty
          ? _mockStories
              .where((s) => s.ageMin <= age && s.ageMax >= age)
              .toList()
          : results;
    } catch (_) {
      return _mockStories
          .where((s) => s.ageMin <= age && s.ageMax >= age)
          .toList();
    }
  }

  // ---------------------------------------------------------------------------
  // getNewStories
  // ---------------------------------------------------------------------------

  Future<List<StorySummary>> getNewStories() async {
    try {
      final snap = await _storiesRef
          .where('isNew', isEqualTo: true)
          .limit(10)
          .get();
      final results =
          snap.docs.map((d) => StorySummary.fromFirestore(d)).toList();
      return results.isEmpty
          ? _mockStories.where((s) => s.isNew).toList()
          : results;
    } catch (_) {
      return _mockStories.where((s) => s.isNew).toList();
    }
  }

  // ---------------------------------------------------------------------------
  // getPopularStories
  // ---------------------------------------------------------------------------

  Future<List<StorySummary>> getPopularStories() async {
    try {
      final snap = await _storiesRef
          .where('isPopular', isEqualTo: true)
          .limit(10)
          .get();
      final results =
          snap.docs.map((d) => StorySummary.fromFirestore(d)).toList();
      return results.isEmpty
          ? _mockStories.where((s) => s.isPopular).toList()
          : results;
    } catch (_) {
      return _mockStories.where((s) => s.isPopular).toList();
    }
  }

  // ---------------------------------------------------------------------------
  // getStoryById — helper used by detail screen
  // ---------------------------------------------------------------------------

  Future<StorySummary?> getStoryById(String storyId) async {
    try {
      final doc = await _storiesRef.doc(storyId).get();
      if (doc.exists) return StorySummary.fromFirestore(doc);
    } catch (_) {}
    // Fallback to mock
    try {
      return _mockStories.firstWhere((s) => s.id == storyId);
    } catch (_) {
      return null;
    }
  }
}
