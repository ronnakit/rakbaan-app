import 'dart:async';

import 'package:fllama/fllama.dart';

import '../core/persona.dart';
import '../models/chat_message.dart';

/// Thin wrapper around `fllama` (Flutter binding for llama.cpp) that turns
/// its callback-based streaming API into a `Stream<String>`, and always
/// injects the "มะลิ" persona as the system message.
///
/// Notes on the underlying API (verified against fllama's source, since its
/// README examples lag the actual code a bit):
/// - `fllamaChat`'s callback receives the *cumulative* text generated so far
///   on every call, not just the newest token/delta. So each stream event
///   below should *replace* the on-screen bubble text, not append to it.
/// - `fllamaChat` returns a `requestId` (an int) once the native call has
///   been dispatched; pass that same id to `fllamaCancelInference` to stop a
///   generation early (e.g. user leaves the chat screen mid-reply).
/// - The model is memory-mapped natively (not fully read into RAM up front),
///   so there is no separate "loading" progress callback on Android/iOS —
///   the first token's latency already includes any load/mmap cost.
class LlamaChatService {
  int? _activeRequestId;

  /// Streams the assistant's reply for [userMessage], given prior [history]
  /// (already trimmed by the caller to fit comfortably in [contextSize]).
  Stream<String> sendMessage({
    required String modelPath,
    required List<ChatMessage> history,
    required String userMessage,
    int maxTokens = 512,
    int contextSize = 2048,
    int numGpuLayers = 0,
    double temperature = 0.4,
  }) {
    final controller = StreamController<String>();

    final messages = <Message>[
      Message(Role.system, Persona.systemPrompt),
      for (final turn in history)
        Message(
          turn.role == MessageRole.user ? Role.user : Role.assistant,
          turn.text,
        ),
      Message(Role.user, userMessage),
    ];

    final request = OpenAiRequest(
      messages: messages,
      modelPath: modelPath,
      // 0 = CPU only. Safe default across low/mid-range devices; raise once
      // you've confirmed the target devices' GPU backend (Metal on iOS,
      // Vulkan on Android) is stable with your build of fllama.
      numGpuLayers: numGpuLayers,
      contextSize: contextSize,
      maxTokens: maxTokens,
      temperature: temperature,
    );

    fllamaChat(request, (response, openAiResponseJsonString, done) {
      if (controller.isClosed) return;
      controller.add(response);
      if (done) {
        _activeRequestId = null;
        controller.close();
      }
    }).then((requestId) {
      _activeRequestId = requestId;
      return requestId;
    }).catchError((Object e, StackTrace st) {
      if (!controller.isClosed) {
        controller.addError(e, st);
        controller.close();
      }
      return -1;
    });

    return controller.stream;
  }

  /// Stops the in-flight generation, if any (e.g. user taps "stop" or backs
  /// out of the chat screen while มะลิ is still typing).
  void cancelActive() {
    final id = _activeRequestId;
    if (id != null) {
      fllamaCancelInference(id);
      _activeRequestId = null;
    }
  }
}
