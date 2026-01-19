
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

  bool get isCelebration => responseType == 'celebration';

  bool get isHint => responseType == 'hint' || responseType == 'silence_hint';

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
