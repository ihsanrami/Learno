/// =============================================================================
/// Chat Message Model - Message Data Structure
/// =============================================================================
/// 🆕 NEW FILE (was inside session_state.dart, now separate)
///
/// Represents a single message in the conversation with full support for:
/// - Text content
/// - Images (AI-generated)
/// - Voice indicators
/// - Response types
/// =============================================================================

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

  /// Check if message has an image
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  /// Check if this is a question that needs an answer
  bool get isQuestion {
    const questionTypes = [
      'guided_practice',
      'independent_practice',
      'mastery_check',
      'chapter_review',
      'question',
    ];
    return responseType != null && questionTypes.contains(responseType);
  }

  /// Check if this is a celebration/completion message
  bool get isCelebration => responseType == 'celebration';

  /// Check if this is a hint message
  bool get isHint => responseType == 'hint' || responseType == 'silence_hint';

  /// Create a copy with modifications
  ChatMessage copyWith({
    String? text,
    bool? isUser,
    String? responseType,
    String? imageUrl,
    bool? isVoiceMessage,
    DateTime? timestamp,
  }) {
    return ChatMessage(
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      responseType: responseType ?? this.responseType,
      imageUrl: imageUrl ?? this.imageUrl,
      isVoiceMessage: isVoiceMessage ?? this.isVoiceMessage,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isUser': isUser,
      'responseType': responseType,
      'imageUrl': imageUrl,
      'isVoiceMessage': isVoiceMessage,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Create from JSON
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'] ?? '',
      isUser: json['isUser'] ?? false,
      responseType: json['responseType'],
      imageUrl: json['imageUrl'],
      isVoiceMessage: json['isVoiceMessage'] ?? false,
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
    );
  }

  @override
  String toString() {
    final sender = isUser ? 'Child' : 'Learno';
    return '[$sender]: $text${hasImage ? ' [+Image]' : ''}';
  }
}
