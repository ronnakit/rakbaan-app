import 'package:flutter/foundation.dart';

import '../core/persona.dart';
import '../models/chat_message.dart';
import '../services/domain_filter_service.dart';

/// Owns the chat transcript and applies the Layer-0 domain filter before any
/// answer is produced.
///
/// The on-device LLM call that used to live here (fllama/llama.cpp running a
/// fine-tuned Gemma 3 270M) was removed on 2026-08-11 after the model
/// architecture pivoted to the Cascading 3-Tier design (Tier 1 hard-coded
/// lookup -> Tier 2 Firestore knowledge base -> Tier 3 external cloud API --
/// see rakbaan_md/03-mali-ai-assistant.md §3). None of the 3 tiers are wired
/// up yet, so on-topic questions currently get a placeholder reply below.
class ChatProvider extends ChangeNotifier {
  ChatProvider() {
    messages.add(
      ChatMessage(
        id: _newId(),
        role: MessageRole.assistant,
        text: Persona.greeting,
        fromModel: false,
      ),
    );
  }

  final DomainFilterService _filter = DomainFilterService();

  final List<ChatMessage> messages = [];
  bool isGenerating = false;

  int _idCounter = 0;
  String _newId() => 'msg_${_idCounter++}';

  Future<void> sendMessage(String rawText) async {
    final text = rawText.trim();
    if (text.isEmpty || isGenerating) return;

    final verdict = _filter.classify(text);
    final isOffTopic = verdict == FilterVerdict.offTopic;
    messages.add(
      ChatMessage(
        id: _newId(),
        role: MessageRole.user,
        text: text,
        fromModel: !isOffTopic,
      ),
    );

    if (isOffTopic) {
      // Answered locally -- no model call needed for an off-topic question.
      messages.add(
        ChatMessage(
          id: _newId(),
          role: MessageRole.assistant,
          text: Persona.offTopicReply,
          fromModel: false,
        ),
      );
      notifyListeners();
      return;
    }

    // TODO(cascade): Tier 1/2/3 not implemented yet (see
    // rakbaan_md/03-mali-ai-assistant.md §3-§5). Placeholder reply keeps the
    // chat screen usable in the meantime, pointing back to the "แจ้งซ่อม" flow
    // which already works end-to-end against MockJobRepository.
    messages.add(
      ChatMessage(
        id: _newId(),
        role: MessageRole.assistant,
        text: 'ขอบคุณสำหรับคำถามค่ะ ตอนนี้มะลิกำลังปรับปรุงระบบตอบคำถามใหม่อยู่ '
            'ลองใช้เมนู "แจ้งซ่อม" ด้านล่างเพื่อสร้างใบแจ้งซ่อมได้เลยนะคะ',
        fromModel: false,
      ),
    );
    notifyListeners();
  }

  void cancelGeneration() {
    // No-op for now -- there is no in-flight model generation to cancel
    // since Tier 1-3 aren't wired up yet. Kept so ChatScreen's stop button
    // doesn't need special-casing.
  }
}
