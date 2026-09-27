import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message.dart';
import '../services/sse_service.dart';
import 'dashboard_provider.dart';

final sseServiceProvider = Provider<SseService>((ref) {
  return SseService();
});

class IsChatStreamingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setStreaming(bool val) => state = val;
}

final isChatStreamingProvider =
    NotifierProvider<IsChatStreamingNotifier, bool>(IsChatStreamingNotifier.new);

class ChatNotifier extends Notifier<List<ChatMessage>> {
  @override
  List<ChatMessage> build() {
    Future.microtask(() => _loadInitialHistory());
    return [];
  }

  Future<void> _loadInitialHistory() async {
    try {
      final api = ref.read(apiServiceProvider);
      final history = await api.getChatHistory();
      if (history.isNotEmpty) {
        state = history;
      }
    } catch (_) {
      // Backend not yet available or empty history
    }
  }

  Future<void> sendMessage(String text) async {
    final cleanText = text.trim();
    final isStreaming = ref.read(isChatStreamingProvider);
    if (cleanText.isEmpty || isStreaming) return;

    final userMsg = ChatMessage(
      role: 'user',
      content: cleanText,
      timestamp: DateTime.now(),
    );

    final momMsg = ChatMessage(
      role: 'mom',
      content: '',
      timestamp: DateTime.now(),
      isStreaming: true,
    );

    state = [...state, userMsg, momMsg];
    ref.read(isChatStreamingProvider.notifier).setStreaming(true);

    final selectedDate = ref.read(selectedDateProvider);
    final sse = ref.read(sseServiceProvider);

    String accumulated = '';

    for (int attempt = 1; attempt <= 2; attempt++) {
      try {
        final stream = sse.streamChat(cleanText, date: selectedDate);

        await for (final token in stream) {
          accumulated += token;
          final updatedList = List<ChatMessage>.from(state);
          if (updatedList.isNotEmpty && updatedList.last.role == 'mom') {
            updatedList[updatedList.length - 1] = updatedList.last.copyWith(
              content: accumulated,
              isStreaming: true,
            );
            state = updatedList;
          }
        }

        if (accumulated.isNotEmpty) {
          break;
        }
      } catch (_) {
        if (attempt < 2) {
          await Future.delayed(const Duration(milliseconds: 1200));
        }
      }
    }

    final finalList = List<ChatMessage>.from(state);
    if (finalList.isNotEmpty && finalList.last.role == 'mom') {
      finalList[finalList.length - 1] = finalList.last.copyWith(
        content: accumulated.isNotEmpty
            ? accumulated
            : 'Unable to receive response from Health Assistant. If quota or API key issue persists, check your GEMINI_API_KEY.',
        isStreaming: false,
      );
      state = finalList;
    }
    ref.read(isChatStreamingProvider.notifier).setStreaming(false);
  }
}

final chatProvider = NotifierProvider<ChatNotifier, List<ChatMessage>>(ChatNotifier.new);
