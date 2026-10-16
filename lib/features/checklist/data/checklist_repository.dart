import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/storage/local_database.dart';
import '../../../core/utils/image_compressor.dart';
import '../domain/checklist_models.dart';

class ChecklistRepository {
  ChecklistRepository({
    required DioClient client,
    required LocalDatabase localDb,
    required ImageCompressor compressor,
  })  : _client = client,
        _localDb = localDb,
        _compressor = compressor;

  final DioClient _client;
  final LocalDatabase _localDb;
  final ImageCompressor _compressor;

  Future<Checklist> getChecklist(String id) async {
    final res = await _client.get<Map<String, dynamic>>(
      '/checklists/$id',
      parser: (raw) => Map<String, dynamic>.from(raw as Map),
    );
    final ck = Checklist.fromJson(res.dados ?? {});
    await _localDb.saveDraft('checklist_$id', res.dados ?? {});
    return ck;
  }

  Future<List<ItemVistoriaCatalogo>> listItensCatalogo() async {
    final res = await _client.get<List<ItemVistoriaCatalogo>>(
      '/itens-vistoria',
      parser: (raw) {
        final list = raw as List? ?? const [];
        return list
            .whereType<Map>()
            .map(
              (e) => ItemVistoriaCatalogo.fromJson(
                Map<String, dynamic>.from(e),
              ),
            )
            .toList();
      },
    );
    return res.dados ?? const [];
  }

  Future<ChecklistItem> upsertItem({
    required String checklistId,
    required String comodoId,
    required String itemVistoriaId,
    required String estado,
    String? observacao,
    String? existingItemId,
  }) async {
    if (existingItemId != null) {
      final res = await _client.put<Map<String, dynamic>>(
        '/checklists/$checklistId/itens/$existingItemId',
        data: {
          'estado': estado,
          if (observacao != null) 'observacao': observacao,
        },
        parser: (raw) => Map<String, dynamic>.from(raw as Map),
      );
      await _localDb.appendOpLog({
        'tipo': 'checklist_item_update',
        'resultado': 'ok',
        'detalhe': existingItemId,
      });
      return ChecklistItem.fromJson(res.dados ?? {});
    }

    final res = await _client.post<Map<String, dynamic>>(
      '/checklists/$checklistId/itens',
      data: {
        'comodo_id': comodoId,
        'item_vistoria_id': itemVistoriaId,
        'estado': estado,
        if (observacao != null) 'observacao': observacao,
      },
      parser: (raw) => Map<String, dynamic>.from(raw as Map),
    );
    await _localDb.appendOpLog({
      'tipo': 'checklist_item_create',
      'resultado': 'ok',
      'detalhe': itemVistoriaId,
    });
    return ChecklistItem.fromJson(res.dados ?? {});
  }

  Future<FotoItem> uploadFoto({
    required String checklistId,
    required String itemId,
    required String filePath,
    Uint8List? bytes,
    String filename = 'foto.jpg',
  }) async {
    late final Uint8List uploadBytes;
    late final String uploadName;

    if (bytes != null) {
      uploadBytes = bytes;
      uploadName = filename;
    } else {
      final compressed = await _compressor.compress(path: filePath);
      uploadBytes = compressed.bytes;
      uploadName =
          compressed.filename.isNotEmpty ? compressed.filename : filename;
    }

    final form = FormData.fromMap({
      'foto': MultipartFile.fromBytes(
        uploadBytes,
        filename: uploadName,
        contentType: MediaType('image', 'jpeg'),
      ),
    });

    try {
      final res = await _client.upload<Map<String, dynamic>>(
        '/checklists/$checklistId/itens/$itemId/fotos',
        formData: form,
        parser: (raw) => Map<String, dynamic>.from(raw as Map),
      );
      await _localDb.appendOpLog({
        'tipo': 'foto_upload',
        'resultado': 'ok',
        'detalhe': itemId,
      });
      final dados = res.dados ?? {};
      return FotoItem(
        id: dados['id'] as String,
        url: dados['url'] as String? ?? '',
      );
    } catch (e) {
      await _localDb.enqueueSync({
        'type': 'foto_upload',
        'checklistId': checklistId,
        'itemId': itemId,
        'localPath': filePath,
        'filename': filename,
      });
      await _localDb.appendOpLog({
        'tipo': 'foto_upload',
        'resultado': 'pendente',
        'detalhe': 'Falha no upload — enfileirado para sincronização',
      });
      rethrow;
    }
  }

  Future<void> deleteFoto({
    required String checklistId,
    required String itemId,
    required String fotoId,
  }) async {
    await _client.delete('/checklists/$checklistId/itens/$itemId/fotos/$fotoId');
    await _localDb.appendOpLog({
      'tipo': 'foto_delete',
      'resultado': 'ok',
      'detalhe': fotoId,
    });
  }

  Future<Checklist> submeter(String checklistId) async {
    final res = await _client.patch<Map<String, dynamic>>(
      '/checklists/$checklistId/submeter',
      parser: (raw) => Map<String, dynamic>.from(raw as Map),
    );
    await _localDb.appendOpLog({
      'tipo': 'checklist_submeter',
      'resultado': 'ok',
      'detalhe': checklistId,
    });
    await _localDb.deleteDraft('checklist_$checklistId');
    return Checklist.fromJson(res.dados ?? {});
  }

  Future<Checklist> aceitar(String checklistId) async {
    final res = await _client.patch<Map<String, dynamic>>(
      '/checklists/$checklistId/aceitar',
      parser: (raw) => Map<String, dynamic>.from(raw as Map),
    );
    return Checklist.fromJson(res.dados ?? {});
  }

  Future<Checklist> rejeitar(
    String checklistId, {
    required String motivo,
  }) async {
    final res = await _client.patch<Map<String, dynamic>>(
      '/checklists/$checklistId/rejeitar',
      data: {'motivo': motivo},
      parser: (raw) => Map<String, dynamic>.from(raw as Map),
    );
    return Checklist.fromJson(res.dados ?? {});
  }
}
