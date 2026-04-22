/// =============================================================================
/// MessageQueue — Sequential Message Display Engine
/// =============================================================================
/// Drives the timed, one-by-one appearance of Learno's message chunks.
///
/// Usage:
///   final queue = MessageQueue(
///     chunks: [...],
///     onShowTypingIndicator: () { ... },
///     onHideTypingIndicator: () { ... },
///     onChunkReady: (text, index) { ... },
///     onComplete: () { ... },
///   )..start();
///
///   // To abort mid-sequence (e.g. user sends a message):
///   queue.cancel();
/// =============================================================================

import 'dart:async';

/// A single queued message chunk — mirrors the backend MessageChunk.
class QueuedChunk {
  final String text;
  final int delayMs;

  const QueuedChunk({required this.text, required this.delayMs});
}

/// Plays a list of [QueuedChunk]s sequentially with their respective delays.
///
/// Sequence for each chunk:
///  1. [onShowTypingIndicator] is called (typing dots become visible).
///  2. After [QueuedChunk.delayMs] milliseconds, [onHideTypingIndicator] is
///     called, then [onChunkReady] delivers the chunk text and its index.
///  3. Steps 1–2 repeat for every chunk.
///  4. [onComplete] fires once all chunks have been delivered.
class MessageQueue {
  final List<QueuedChunk> _chunks;

  /// Called immediately before each chunk's delay countdown begins.
  final void Function() onShowTypingIndicator;

  /// Called just before the chunk is delivered to the caller.
  final void Function() onHideTypingIndicator;

  /// Delivers chunk text and its 0-based index in the original list.
  final void Function(String text, int index) onChunkReady;

  /// Fires once every chunk has been delivered and no cancellation occurred.
  final void Function() onComplete;

  bool _cancelled = false;
  bool _running = false;

  MessageQueue({
    required List<QueuedChunk> chunks,
    required this.onShowTypingIndicator,
    required this.onHideTypingIndicator,
    required this.onChunkReady,
    required this.onComplete,
  }) : _chunks = List.unmodifiable(chunks);

  /// Whether the queue is currently playing.
  bool get isRunning => _running;

  /// Start playing chunks from the beginning.
  void start() {
    if (_running || _cancelled) return;
    if (_chunks.isEmpty) {
      onComplete();
      return;
    }
    _running = true;
    onShowTypingIndicator();
    _scheduleChunk(0);
  }

  /// Abort all pending chunks. Already-shown chunks are unaffected.
  void cancel() {
    _cancelled = true;
    _running = false;
  }

  void _scheduleChunk(int index) {
    if (_cancelled) return;

    final chunk = _chunks[index];

    Future.delayed(Duration(milliseconds: chunk.delayMs), () {
      if (_cancelled) return;

      onHideTypingIndicator();
      onChunkReady(chunk.text, index);

      final next = index + 1;
      if (next < _chunks.length) {
        onShowTypingIndicator();
        _scheduleChunk(next);
      } else {
        _running = false;
        onComplete();
      }
    });
  }
}
