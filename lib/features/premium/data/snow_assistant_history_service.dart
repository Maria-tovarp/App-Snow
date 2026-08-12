import 'package:supabase_flutter/supabase_flutter.dart';

class SnowAssistantHistoryService {
  SnowAssistantHistoryService._();
  static final SnowAssistantHistoryService instance =
      SnowAssistantHistoryService._();
  final SupabaseClient _supabase = Supabase.instance.client;

  String get _userId {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Debes iniciar sesión para usar Snow Assistant.');
    }
    return user.id;
  }

  Future<String> createConversation(String firstMessage) async {
    final data = await _supabase
        .from('snow_assistant_conversations')
        .insert({
          'user_id': _userId,
          'title': _createTitle(firstMessage),
        })
        .select('id')
        .single();
    return data['id'].toString();
  }

  Future<List<Map<String, dynamic>>> getConversations({int limit = 20}) async {
    final data = await _supabase
        .from('snow_assistant_conversations')
        .select(
          'id, title, created_at, updated_at',
        )
        .eq('user_id', _userId)
        .order('updated_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> getMessages(String conversationId) async {
    final data = await _supabase
        .from('snow_assistant_messages')
        .select(
          'id, role, content, created_at',
        )
        .eq('conversation_id', conversationId)
        .eq('user_id', _userId)
        .order('id');
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> saveExchange(
      {required String conversationId,
      required String userMessage,
      required String assistantMessage}) async {
    await _supabase.from('snow_assistant_messages').insert([
      {
        'conversation_id': conversationId,
        'user_id': _userId,
        'role': 'user',
        'content': userMessage
      },
      {
        'conversation_id': conversationId,
        'user_id': _userId,
        'role': 'assistant',
        'content': assistantMessage
      },
    ]);
    await _supabase
        .from('snow_assistant_conversations')
        .update({
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', conversationId)
        .eq('user_id', _userId);
  }

  Future<void> deleteConversation(String id) => _supabase
      .from('snow_assistant_conversations')
      .delete()
      .eq('id', id)
      .eq('user_id', _userId);
  Future<void> clearHistory() => _supabase
      .from('snow_assistant_conversations')
      .delete()
      .eq('user_id', _userId);

  String _createTitle(String message) {
    final cleaned = message.replaceAll(RegExp(r'\s+'), ' ').trim();
    return cleaned.length <= 42 ? cleaned : '${cleaned.substring(0, 42)}…';
  }
}
