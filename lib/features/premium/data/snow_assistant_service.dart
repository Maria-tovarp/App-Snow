import 'package:supabase_flutter/supabase_flutter.dart';

class SnowAssistantResult {
  const SnowAssistantResult({
    required this.answer,
    this.outOfScope = false,
    this.limit,
    this.used,
    this.remaining,
    this.resetAt,
  });

  final String answer;
  final bool outOfScope;
  final int? limit;
  final int? used;
  final int? remaining;
  final DateTime? resetAt;
}

class SnowAssistantUsage {
  const SnowAssistantUsage({
    required this.limit,
    required this.used,
    required this.remaining,
    this.resetAt,
  });

  final int limit;
  final int used;
  final int remaining;
  final DateTime? resetAt;
}

class SnowAssistantService {
  SnowAssistantService._();

  static final SnowAssistantService instance = SnowAssistantService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  Future<SnowAssistantResult> ask({
    required String message,
    Map<String, dynamic>? context,
  }) async {
    final response = await _supabase.functions.invoke(
      'snow-assistant',
      body: {'message': message, 'context': context ?? {}},
    );
    final data = response.data;

    if (data is! Map) {
      throw Exception('Snow Assistant devolvió una respuesta inválida.');
    }
    if (data['success'] != true) {
      throw Exception(
        data['error']?.toString() ?? 'Snow Assistant no pudo responder.',
      );
    }

    final usage = data['usage'];
    if (usage is! Map) {
      return SnowAssistantResult(
        answer: data['answer']?.toString() ?? '',
        outOfScope: data['outOfScope'] == true,
      );
    }

    return SnowAssistantResult(
      answer: data['answer']?.toString() ?? '',
      outOfScope: data['outOfScope'] == true,
      limit: (usage['limit'] as num?)?.toInt() ?? 50,
      used: (usage['used'] as num?)?.toInt() ?? 0,
      remaining: (usage['remaining'] as num?)?.toInt() ?? 0,
      resetAt: usage['resetAt'] == null
          ? null
          : DateTime.tryParse(usage['resetAt'].toString()),
    );
  }

  Future<SnowAssistantUsage> getUsage() async {
    final data = await _supabase.rpc('get_snow_assistant_usage');
    if (data is! Map) {
      return const SnowAssistantUsage(limit: 50, used: 0, remaining: 50);
    }

    return SnowAssistantUsage(
      limit: (data['limit'] as num?)?.toInt() ?? 50,
      used: (data['used'] as num?)?.toInt() ?? 0,
      remaining: (data['remaining'] as num?)?.toInt() ?? 50,
      resetAt: data['reset_at'] == null
          ? null
          : DateTime.tryParse(data['reset_at'].toString()),
    );
  }
}
