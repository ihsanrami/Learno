import 'dart:async';

class QueuedChunk {
  final String text;
  final int delayMs;

  const QueuedChunk({required this.text, required this.delayMs});
}

/// Plays [QueuedChunk]s sequentially, showing a typing indicator between each.
///
/// For each chunk: [onShowTypingIndicator] fires, then after [QueuedChunk.delayMs]
/// ms [onHideTypingIndicator] and [onChunkReady] fire. [onComplete] fires after
/// all chunks. Call [cancel] to abort mid-sequence.
class MessageQueue {
  final List<QueuedChunk> _chunks;

  final void Function() onShowTypingIndicator;
  final void Function() onHideTypingIndicator;
  final void Function(String text, int index) onChunkReady;
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

  bool get isRunning => _running;

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
