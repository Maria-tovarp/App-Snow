import 'package:supabase_flutter/supabase_flutter.dart';
import 'meta_model.dart';

import 'package:helloworld/features/metas/domain/repositories/meta_repository_port.dart';

class MetaRepository implements MetaRepositoryPort {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<MetaModel>> getMetas() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final response = await _client
        .from('metas')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return (response as List).map((e) => MetaModel.fromJson(e)).toList();
  }

  Future<void> createMeta({
    required String titulo,
    String? descripcion,
    String? periodo,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('No hay usuario autenticado');
    }

    await _client.from('metas').insert({
      'titulo': titulo,
      'descripcion': descripcion,
      'periodo': periodo,
      'estado': 'pendiente',
      'user_id': user.id,
    });
  }

  Future<void> completarMeta(String id) async {
    await _client.from('metas').update({
      'estado': 'completada',
    }).eq('id', id);
  }

  Future<void> deleteMeta(String id) async {
    await _client.from('metas').delete().eq('id', id);
  }
}
