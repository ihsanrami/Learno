class ChatMessage {
  final String text;
  final bool isUser;
  final String? responseType;
  final String? imageUrl;
  final bool isVoiceMessage;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.responseType,
    this.imageUrl,
    this.isVoiceMessage = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  @override
  String toString() {
    final sender = isUser ? 'Child' : 'Learno';
    return '[$sender]: $text${hasImage ? ' [+Image]' : ''}';
  }
}
