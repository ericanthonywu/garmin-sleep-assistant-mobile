import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/constants.dart';

class SseService {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(minutes: 3),
    headers: {
      'Accept': 'text/event-stream',
      'Content-Type': 'application/json',
    },
  ));

  Stream<String> streamChat(String message, {String? date}) async* {
    final url = '${AppConstants.apiBaseUrl}/chat';
    final payload = <String, dynamic>{'message': message};
    if (date != null) {
      payload['date'] = date;
    }

    try {
      final response = await _dio.post<ResponseBody>(
        url,
        data: payload,
        options: Options(
          responseType: ResponseType.stream,
        ),
      );

      final stream = response.data?.stream;
      if (stream == null) {
        yield 'Unable to establish streaming connection to Health Assistant. Please verify backend status.';
        return;
      }

      String buffer = '';

      await for (final chunk in stream) {
        buffer += utf8.decode(chunk);

        while (buffer.contains('\n\n')) {
          final idx = buffer.indexOf('\n\n');
          final rawEvent = buffer.substring(0, idx);
          buffer = buffer.substring(idx + 2);

          for (final line in rawEvent.split('\n')) {
            if (line.startsWith('data: ')) {
              final dataStr = line.substring(6).trim();
              if (dataStr == '[DONE]') {
                return;
              }

              try {
                final json = jsonDecode(dataStr) as Map<String, dynamic>;
                if (json.containsKey('text')) {
                  yield json['text'] as String;
                }
                if (json.containsKey('error')) {
                  yield json['error'] as String;
                  return;
                }
              } catch (_) {
                // Ignore incomplete JSON chunks
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[SseService] Streaming error: $e');
      yield 'Unable to reach Health Assistant backend. Please check server connectivity.';
    }
  }
}
