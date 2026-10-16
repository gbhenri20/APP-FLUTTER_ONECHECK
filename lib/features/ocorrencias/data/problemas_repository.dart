
import '../../../core/network/dio_client.dart';
import '../domain/problema.dart';

class ProblemasRepository {
  ProblemasRepository(this._client);
  final DioClient _client;

  Future<List<Problema>> listByContrato(String contratoId) async {
    final res = await _client.get<List<Problema>>(
      '/contratos/$contratoId/problemas',
      parser: (raw) {
        final list = raw as List? ?? const [];
        return list
            .whereType<Map>()
            .map((e) => Problema.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      },
    );
    return res.dados ?? const [];
  }

  Future<Problema> get(String id) async {
    final res = await _client.get<Map<String, dynamic>>(
      '/problemas/$id',
      parser: (raw) => Map<String, dynamic>.from(raw as Map),
    );
    return Problema.fromJson(res.dados ?? {});
  }

  Future<Problema> criar({
    required String contratoId,
    required String titulo,
    required String descricao,
    String? comodoId,
    String prioridade = 'media',
  }) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/contratos/$contratoId/problemas',
      data: {
        'titulo': titulo,
        'descricao': descricao,
        'prioridade': prioridade,
        if (comodoId != null) 'comodo_id': comodoId,
      },
      parser: (raw) => Map<String, dynamic>.from(raw as Map),
    );
    return Problema.fromJson(res.dados ?? {});
  }
}
