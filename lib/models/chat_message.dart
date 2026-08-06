enum MessageRole { user, assistant }

class ChatMessage {
  final String id;
  final MessageRole role;
  String text;
  final DateTime timestamp;

  /// True while the assistant reply is still being streamed token-by-token.
  bool isStreaming;

  ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    DateTime? timestamp,
    this.isStreaming = false,
  }) : timestamp = timestamp ?? DateTime.now();
}
