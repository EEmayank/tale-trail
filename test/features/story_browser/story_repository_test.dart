import 'package:flutter_test/flutter_test.dart';
import 'package:kids_stories/features/story_browser/data/repositories/story_repository.dart';

void main() {
  group('StoryRepository mock data', () {
    late StoryRepository repository;

    setUp(() {
      repository = StoryRepository();
    });

    test('fetchStories returns non-empty list from mock data', () async {
      final stories = await repository.fetchStories();
      expect(stories, isNotEmpty);
    });

    test('mock stories have required fields', () async {
      final stories = await repository.fetchStories();
      for (final story in stories) {
        expect(story.id, isNotEmpty);
        expect(story.title, isNotEmpty);
        expect(story.ageMin, greaterThanOrEqualTo(3));
        expect(story.ageMax, lessThanOrEqualTo(12));
        expect(story.durationMinutes, greaterThan(0));
      }
    });

    test('getStoriesForKid(5) returns age-appropriate stories', () async {
      final stories = await repository.getStoriesForKid(5);
      for (final story in stories) {
        expect(story.ageMin, lessThanOrEqualTo(5));
        expect(story.ageMax, greaterThanOrEqualTo(5));
      }
    });

    test('searchStories returns matching results', () async {
      final results = await repository.searchStories('fox');
      expect(results.any((s) => s.title.toLowerCase().contains('fox')), isTrue);
    });

    test('getNewStories filters new stories', () async {
      final stories = await repository.getNewStories();
      expect(stories.every((s) => s.isNew), isTrue);
    });

    test('getPopularStories filters popular stories', () async {
      final stories = await repository.getPopularStories();
      expect(stories.every((s) => s.isPopular), isTrue);
    });
  });
}
