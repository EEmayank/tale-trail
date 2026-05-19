import 'package:flutter_test/flutter_test.dart';
import 'package:kids_stories/features/story_player/data/models/story_choice.dart';
import 'package:kids_stories/features/story_player/data/models/story_step.dart';
import 'package:kids_stories/features/story_player/data/models/story_tree.dart';

void main() {
  group('StoryTree', () {
    late StoryTree sampleTree;

    setUp(() {
      sampleTree = StoryTree(
        storyId: 'test_story',
        title: 'Test Story',
        rootStepId: 'step_1',
        steps: {
          'step_1': StoryStep(
            id: 'step_1',
            text: 'Once upon a time...',
            illustrationUrl: 'https://example.com/step1.svg',
            audioUrl: 'https://example.com/step1.mp3',
            choices: [
              StoryChoice(
                id: 'choice_a',
                label: 'Go left',
                nextStepId: 'step_2a',
              ),
              StoryChoice(
                id: 'choice_b',
                label: 'Go right',
                nextStepId: 'step_2b',
              ),
            ],
            isEnding: false,
          ),
          'step_2a': StoryStep(
            id: 'step_2a',
            text: 'You went left and found treasure!',
            illustrationUrl: 'https://example.com/step2a.svg',
            audioUrl: 'https://example.com/step2a.mp3',
            choices: [],
            isEnding: true,
            endingTitle: 'The Treasure Hunter',
          ),
          'step_2b': StoryStep(
            id: 'step_2b',
            text: 'You went right and met a dragon!',
            illustrationUrl: 'https://example.com/step2b.svg',
            audioUrl: 'https://example.com/step2b.mp3',
            choices: [],
            isEnding: true,
            endingTitle: 'The Dragon Friend',
          ),
        },
        totalStepCount: 3,
        version: 1,
      );
    });

    test('getStep returns correct step by id', () {
      final step = sampleTree.getStep('step_1');
      expect(step, isNotNull);
      expect(step!.id, equals('step_1'));
      expect(step.choices.length, equals(2));
    });

    test('getStep returns null for unknown id', () {
      final step = sampleTree.getStep('nonexistent');
      expect(step, isNull);
    });

    test('root step has correct choices', () {
      final root = sampleTree.getStep(sampleTree.rootStepId)!;
      expect(root.choices.map((c) => c.nextStepId).toList(),
          containsAll(['step_2a', 'step_2b']));
    });

    test('ending steps have isEnding=true', () {
      final endingA = sampleTree.getStep('step_2a')!;
      final endingB = sampleTree.getStep('step_2b')!;
      expect(endingA.isEnding, isTrue);
      expect(endingB.isEnding, isTrue);
    });

    test('fromJson roundtrip preserves all data', () {
      final json = sampleTree.toJson();
      final restored = StoryTree.fromJson(json);
      expect(restored.storyId, equals(sampleTree.storyId));
      expect(restored.rootStepId, equals(sampleTree.rootStepId));
      expect(restored.steps.length, equals(sampleTree.steps.length));
    });
  });

  group('StoryStep', () {
    test('choice nextStepId links correctly', () {
      final choice = StoryChoice(
        id: 'c1',
        label: 'Take the gem',
        nextStepId: 'step_3',
      );
      expect(choice.nextStepId, equals('step_3'));
    });
  });
}
