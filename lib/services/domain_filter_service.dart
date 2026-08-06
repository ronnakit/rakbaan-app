import '../core/persona.dart';

enum FilterVerdict {
  /// Clearly about home repair — send straight to the model.
  onTopic,

  /// Greeting / small talk — let the model handle it too (cheap, and needed
  /// so it can introduce itself).
  greeting,

  /// No home-repair keyword matched — answer with [Persona.offTopicReply]
  /// locally and skip the (comparatively expensive) LLM call entirely.
  offTopic,
}

/// Cheap, fully offline keyword pre-filter that runs before every LLM call.
///
/// Why keyword-based and not another small classifier model:
/// - It costs ~0ms and 0 battery, vs. seconds of on-device generation.
/// - The persona was fine-tuned on a single narrow domain (home repair), so a
///   clearly off-topic message (politics, recipes, homework, "เล่าเรื่องตลก")
///   is very unlikely to produce anything useful anyway — better to save the
///   battery/heat/latency and answer instantly.
///
/// Why this is *not* the only line of defense:
/// - Thai has huge paraphrase variety; a fixed keyword list will always miss
///   valid rephrasings ("ที่บ้านมีเสียงดังแปลกๆ ตอนเปิดเครื่องปรับอากาศ" has no
///   exact keyword like "แอร์" but is clearly on-topic once "เครื่องปรับอากาศ"
///   is present — but shorter paraphrases can still slip through the cracks).
/// - So [Persona.systemPrompt] also carries an explicit instruction (rule 4)
///   telling the model itself to politely decline off-topic questions. That
///   makes the model the real safety net; this filter is just a fast path for
///   the *obvious* cases, saving compute/battery on a mobile device.
///
/// Recommendation if the keyword list proves too strict/loose in testing:
/// log (locally, on-device only) the text of messages that get [offTopic]'d,
/// review them periodically, and fold recurring false negatives into
/// [DomainKeywords.homeRepairKeywords].
class DomainFilterService {
  FilterVerdict classify(String rawMessage) {
    final text = rawMessage.trim().toLowerCase();
    if (text.isEmpty) return FilterVerdict.offTopic;

    for (final greeting in DomainKeywords.greetingKeywords) {
      if (text.contains(greeting.toLowerCase())) {
        return FilterVerdict.greeting;
      }
    }

    for (final keyword in DomainKeywords.homeRepairKeywords) {
      if (text.contains(keyword.toLowerCase())) {
        return FilterVerdict.onTopic;
      }
    }

    return FilterVerdict.offTopic;
  }
}
