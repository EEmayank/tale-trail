import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kids_stories/core/theme/tale_colors.dart';
import 'package:kids_stories/features/story_player/presentation/providers/audio_provider.dart';
import 'package:kids_stories/features/story_player/presentation/widgets/speaking_indicator.dart';

/// Floating pill-shaped audio controls widget.
///
/// Shows:
///   - Play / pause button (or a 16 px [CircularProgressIndicator] when
///     buffering).
///   - [SpeakingIndicator] — animated bouncing dots while playing.
///   - Position label formatted as `"0:32 / 2:15"`.
///
/// The widget is transparent to touches when the audio state has an error,
/// so the reader can still interact with the story text below.
class AudioControls extends ConsumerWidget {
  const AudioControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audio = ref.watch(audioPlayerProvider);
    final audioNotifier = ref.read(audioPlayerProvider.notifier);

    // Don't render if an unrecoverable error has occurred — fall back to
    // text-only mode and hide the controls entirely.
    if (audio.error != null) return const SizedBox.shrink();

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: TaleColors.warmGrey900.withAlpha(204), // 80% opacity
        borderRadius: const BorderRadius.all(Radius.circular(100)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(51),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Play / Pause / Buffer ──────────────────────────────────────
          _PlayPauseButton(
            isPlaying: audio.isPlaying,
            isBuffering: audio.isBuffering,
            onPlay: audioNotifier.resume,
            onPause: audioNotifier.pause,
          ),

          const SizedBox(width: 8),

          // ── Speaking indicator ─────────────────────────────────────────
          SpeakingIndicator(
            isPlaying: audio.isPlaying,
            color: TaleColors.warmGold,
          ),

          const SizedBox(width: 10),

          // ── Position label ─────────────────────────────────────────────
          Text(
            '${audio.positionLabel} / ${audio.durationLabel}',
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Nunito',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _PlayPauseButton
// ---------------------------------------------------------------------------

class _PlayPauseButton extends StatelessWidget {
  const _PlayPauseButton({
    required this.isPlaying,
    required this.isBuffering,
    required this.onPlay,
    required this.onPause,
  });

  final bool isPlaying;
  final bool isBuffering;
  final VoidCallback onPlay;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    if (isBuffering) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    return GestureDetector(
      onTap: isPlaying ? onPause : onPlay,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}
