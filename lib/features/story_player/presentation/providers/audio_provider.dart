import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

// ---------------------------------------------------------------------------
// AudioState
// ---------------------------------------------------------------------------

/// Immutable snapshot of the audio player's runtime state.
class AudioState {
  const AudioState({
    this.isPlaying = false,
    this.isBuffering = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.error,
  });

  /// Whether the player is actively outputting audio.
  final bool isPlaying;

  /// Whether the player is waiting for audio data (network or disk I/O).
  final bool isBuffering;

  /// Current playback position.
  final Duration position;

  /// Total duration of the loaded track. [Duration.zero] while loading.
  final Duration duration;

  /// Non-null when an unrecoverable error occurred after all retries.
  final String? error;

  // ---------------------------------------------------------------------------
  // Derived helpers
  // ---------------------------------------------------------------------------

  /// Playback progress in the range [0.0, 1.0].
  double get progress {
    if (duration == Duration.zero) return 0.0;
    final raw = position.inMilliseconds / duration.inMilliseconds;
    return raw.clamp(0.0, 1.0);
  }

  /// Formatted elapsed time string, e.g. `"1:34"`.
  String get positionLabel => _formatDuration(position);

  /// Formatted total duration string, e.g. `"3:12"`.
  String get durationLabel => _formatDuration(duration);

  static String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ---------------------------------------------------------------------------
  // copyWith
  // ---------------------------------------------------------------------------

  AudioState copyWith({
    bool? isPlaying,
    bool? isBuffering,
    Duration? position,
    Duration? duration,
    String? error,
    bool clearError = false,
  }) =>
      AudioState(
        isPlaying: isPlaying ?? this.isPlaying,
        isBuffering: isBuffering ?? this.isBuffering,
        position: position ?? this.position,
        duration: duration ?? this.duration,
        error: clearError ? null : (error ?? this.error),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AudioState &&
          isPlaying == other.isPlaying &&
          isBuffering == other.isBuffering &&
          position == other.position &&
          duration == other.duration &&
          error == other.error;

  @override
  int get hashCode =>
      Object.hash(isPlaying, isBuffering, position, duration, error);

  @override
  String toString() =>
      'AudioState(isPlaying: $isPlaying, isBuffering: $isBuffering, '
      'position: $positionLabel / $durationLabel, error: $error)';
}

// ---------------------------------------------------------------------------
// AudioNotifier
// ---------------------------------------------------------------------------

/// StateNotifier that owns the [AudioPlayer] and exposes audio controls.
///
/// Audio session handling:
///   - Requests audio focus with `AudioSessionType.speech` on first load.
///   - Pauses on interruption (phone calls, other media apps).
///   - Resumes when focus is regained (if interrupted, not permanently lost).
///
/// Error handling:
///   - On load / play failure, retries up to 2× with a 1-second back-off.
///   - After all retries, sets [AudioState.error] so the UI can fall back to
///     text-only mode.
class AudioNotifier extends StateNotifier<AudioState> {
  AudioNotifier() : super(const AudioState()) {
    _player = AudioPlayer();
    _initSession();
    _subscribeToPlayerStreams();
  }

  late final AudioPlayer _player;
  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<AudioInterruptionEvent>? _interruptionSub;
  bool _interruptedBySystem = false;

  // ---------------------------------------------------------------------------
  // Session initialisation
  // ---------------------------------------------------------------------------

  Future<void> _initSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.duckOthers,
        avAudioSessionMode: AVAudioSessionMode.spokenAudio,
        avAudioSessionRouteSharingPolicy:
            AVAudioSessionRouteSharingPolicy.defaultPolicy,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          flags: AndroidAudioFlags.none,
          usage: AndroidAudioUsage.media,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: true,
      ));

      _interruptionSub = session.interruptionEventStream.listen((event) {
        if (event.begin) {
          // Audio focus lost — pause immediately.
          if (state.isPlaying) {
            _interruptedBySystem = true;
            _player.pause();
          }
        } else {
          // Audio focus regained.
          if (_interruptedBySystem &&
              event.type == AudioInterruptionType.pause) {
            _interruptedBySystem = false;
            _player.play();
          } else {
            _interruptedBySystem = false;
          }
        }
      });
    } catch (e) {
      debugPrint('[AudioNotifier] Session init error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Stream subscriptions
  // ---------------------------------------------------------------------------

  void _subscribeToPlayerStreams() {
    _playerStateSub = _player.playerStateStream.listen((playerState) {
      final isPlaying = playerState.playing;
      final isBuffering = playerState.processingState == ProcessingState.loading
          || playerState.processingState == ProcessingState.buffering;

      final duration = _player.duration ?? Duration.zero;

      if (!mounted) return;
      state = state.copyWith(
        isPlaying: isPlaying,
        isBuffering: isBuffering,
        duration: duration,
      );
    });

    _positionSub = _player.positionStream.listen((position) {
      if (!mounted) return;
      state = state.copyWith(position: position);
    });
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Loads and plays a remote audio URL. Retries up to 2× on failure.
  Future<void> loadAndPlay(String url) async {
    if (url.isEmpty) return;
    state = state.copyWith(
      isBuffering: true,
      isPlaying: false,
      position: Duration.zero,
      duration: Duration.zero,
      clearError: true,
    );

    await _loadWithRetry(() => _player.setUrl(url));
  }

  /// Loads and plays an audio file from a local absolute path.
  Future<void> loadLocalAndPlay(String localPath) async {
    if (localPath.isEmpty) return;
    state = state.copyWith(
      isBuffering: true,
      isPlaying: false,
      position: Duration.zero,
      duration: Duration.zero,
      clearError: true,
    );

    await _loadWithRetry(
      () => _player.setFilePath(localPath),
    );
  }

  /// Pauses playback if currently playing.
  Future<void> pause() async {
    try {
      await _player.pause();
    } catch (e) {
      debugPrint('[AudioNotifier] pause error: $e');
    }
  }

  /// Resumes playback if paused.
  Future<void> resume() async {
    try {
      await _player.play();
    } catch (e) {
      debugPrint('[AudioNotifier] resume error: $e');
    }
  }

  /// Stops playback and resets position.
  Future<void> stop() async {
    try {
      await _player.stop();
      state = state.copyWith(
        isPlaying: false,
        isBuffering: false,
        position: Duration.zero,
      );
    } catch (e) {
      debugPrint('[AudioNotifier] stop error: $e');
    }
  }

  /// Seeks to [position] in the current track.
  Future<void> seek(Duration position) async {
    try {
      await _player.seek(position);
    } catch (e) {
      debugPrint('[AudioNotifier] seek error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Retry logic
  // ---------------------------------------------------------------------------

  Future<void> _loadWithRetry(
    Future<Duration?> Function() loader, {
    int maxAttempts = 3,
  }) async {
    int attempt = 0;
    while (attempt < maxAttempts) {
      try {
        await loader();
        await _player.play();
        if (!mounted) return;
        state = state.copyWith(isBuffering: false, clearError: true);
        return;
      } catch (e) {
        attempt++;
        debugPrint(
            '[AudioNotifier] Load attempt $attempt failed: $e');
        if (attempt < maxAttempts) {
          await Future<void>.delayed(const Duration(seconds: 1));
        }
      }
    }

    // All retries exhausted.
    if (mounted) {
      state = state.copyWith(
        isPlaying: false,
        isBuffering: false,
        error: 'Could not load audio. Reading in text-only mode.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Dispose
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    _playerStateSub?.cancel();
    _positionSub?.cancel();
    _interruptionSub?.cancel();
    _player.dispose();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// StateNotifierProvider that exposes [AudioNotifier] and [AudioState].
final audioPlayerProvider =
    StateNotifierProvider<AudioNotifier, AudioState>((ref) {
  return AudioNotifier();
});

/// StreamProvider that emits the current playback progress as a [double] in
/// the range [0.0, 1.0]. Widgets that only need the progress bar can watch
/// this provider to avoid unnecessary rebuilds.
final audioProgressProvider = StreamProvider<double>((ref) {
  final notifier = ref.watch(audioPlayerProvider.notifier);

  return notifier._player.positionStream.map((position) {
    final duration = notifier._player.duration;
    if (duration == null || duration == Duration.zero) return 0.0;
    return (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
  });
});
