import 'package:flutter/foundation.dart';

import '../core/persona.dart';
import '../models/chat_message.dart';
import '../services/domain_filter_service.dart';
import '../services/llama_chat_service.dart';
import '../services/model_manager_service.dart';

enum ModelLoadStatus { notStarted, downloading, ready, error }

/// Owns the chat transcript and orchestrates: domain filter -> model call ->
/// streaming UI updates. This is the only class the UI talks to.
class ChatProvider extends ChangeNotifier {
  ChatProvider({ModelManagerService? modelManager})
      : _modelManager = modelManager ?? ModelManagerService();

  final ModelManagerService _modelManager;
  final DomainFilterService _filter = DomainFilterService();
  final LlamaChatService _llamaService = LlamaChatService();

  /// How many prior messages to feed back as context. Keeps the prompt well
  /// under `contextSize` (2048 tokens) without any extra token-counting.
  static const int _maxHistoryMessages = 6;

  ModelLoadStatus status = ModelLoadStatus.notStarted;
  double downloadProgress = 0.0;
  String? errorMessage;
  String? _modelPath;

  final List<ChatMessage> messages = [];
  bool isGenerating = false;

  int _idCounter = 0;
  String _newId() => 'msg_${_idCounter++}';

  Future<void> initializeModel() async {
    status = ModelLoadStatus.downloading;
    downloadProgress = 0;
    errorMessage = null;
    notifyListeners();

    try {
      final path = await _modelManager.ensureModelPath(
        onProgress: (progress) {
          downloadProgress = progress;
          notifyListeners();
        },
      );
      _modelPath = path;
      status = ModelLoadStatus.ready;
      messages.add(
        ChatMessage(
          id: _newId(),
          role: MessageRole.assistant,
          text: Persona.greeting,
        ),
      );
      notifyListeners();
    } catch (e) {
      status = ModelLoadStatus.error;
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> sendMessage(String rawText) async {
    final text = rawText.trim();
    if (text.isEmpty || isGenerating || _modelPath == null) return;

    final verdict = _filter.classify(text);
    final history = _recentHistory();

    messages.add(ChatMessage(id: _newId(), role: MessageRole.user, text: text));

    if (verdict == FilterVerdict.offTopic) {
      // Answered locally -- no LLM call, no battery/latency cost.
      messages.add(
        ChatMessage(
          id: _newId(),
          role: MessageRole.assistant,
          text: Persona.offTopicReply,
        ),
      );
      notifyListeners();
      return;
    }

    final assistantMessage = ChatMessage(
      id: _newId(),
      role: MessageRole.assistant,
      text: '',
      isStreaming: true,
    );
    messages.add(assistantMessage);
    isGenerating = true;
    notifyListeners();

    try {
      await for (final partialText in _llamaService.sendMessage(
        modelPath: _modelPath!,
        history: history,
        userMessage: text,
      )) {
        assistantMessage.text = partialText;
        notifyListeners();
      }
    } catch (e) {
      assistantMessage.text =
          'ขอโทษค่ะ เกิดข้อผิดพลาดระหว่างประมวลผลคำถาม ลองใหม่อีกครั้งนะคะ';
    } finally {
      assistantMessage.isStreaming = false;
      isGenerating = false;
      notifyListeners();
    }
  }

  void cancelGeneration() {
    _llamaService.cancelActive();
  }

  List<ChatMessage> _recentHistory() {
    final completedTurns = messages.where((m) => !m.isStreaming).toList();
    if (completedTurns.length <= _maxHistoryMessages) return completedTurns;
    return completedTurns.sublist(completedTurns.length - _maxHistoryMessages);
  }

  @override
  void dispose() {
    _llamaService.cancelActive();
    super.dispose();
  }
}
