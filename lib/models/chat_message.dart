enum MessageRole { user, assistant }

class ChatMessage {
  final String id;
  final MessageRole role;
  String text;
  final DateTime timestamp;

  /// True while the assistant reply is still being streamed token-by-token.
  bool isStreaming;

  /// False for canned/local-only turns (the initial greeting, the off-topic
  /// refusal) that were never actually part of a model exchange. Chat
  /// template engines (Gemma 3's in particular) enforce strict
  /// user/assistant/user/assistant alternation starting with `user` -- a
  /// canned assistant-only turn like the greeting would break that
  /// invariant if included, so history-building must exclude these.
  final bool fromModel;

  ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    DateTime? timestamp,
    this.isStreaming = false,
    this.fromModel = true,
  }) : timestamp = timestamp ?? DateTime.now();
}
