
import '../../../core/network/dio_client.dart';
import '../../checklist/domain/checklist_models.dart';

/// Agenda montada a partir de contratos + checklists + agendamentos da API.
/// Não há endpoint GET /agendamentos global — isso é uma limitação documentada.
class AgendaRepository {
  AgendaRepository(this._client);

  final DioClient _client;

  Future<List<AgendaItem>> carregarAgenda({
    bool ocultarEncerramento = true,
  }) async {
    final contratosRes = await _client.get<List<Contrato>>(
      '/contratos',
      query: {'por_pagina': 100},
      parser: (raw) {
        final list = raw as List? ?? const [];
        return list
            .whereType<Map>()
            .map((e) => Contrato.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      },
    );
    final contratos = contratosRes.dados ?? const [];
    final items = <AgendaItem>[];

    for (final contrato in contratos) {
      final checksRes = await _client.get<List<Checklist>>(
        '/contratos/${contrato.id}/checklists',
        parser: (raw) {
          final list = raw as List? ?? const [];
          return list
              .whereType<Map>()
              .map((e) => Checklist.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        },
      );
      final checklists = checksRes.dados ?? const [];

      Agendamento? agendamentoMatch;
      try {
        final agRes = await _client.get<List<Agendamento>>(
          '/contratos/${contrato.id}/agendamentos',
          parser: (raw) {
            final list = raw as List? ?? const [];
            return list
                .whereType<Map>()
                .map((e) => Agendamento.fromJson(Map<String, dynamic>.from(e)))
                .toList();
          },
        );
        final ags = agRes.dados ?? const [];
        // Match por tipo; se houver vários, pega o mais recente por data.
        for (final ck in checklists) {
          final matches = ags.where((a) => a.tipo == ck.tipo).toList();
          if (matches.isNotEmpty) {
            matches.sort((a, b) {
              final da = a.dataAgendada ?? DateTime.fromMillisecondsSinceEpoch(0);
              final db = b.dataAgendada ?? DateTime.fromMillisecondsSinceEpoch(0);
              return db.compareTo(da);
            });
            agendamentoMatch = matches.first;
          } else {
            agendamentoMatch = null;
          }

          if (ocultarEncerramento && ck.isEncerramento) {
            continue;
          }

          Imovel? imovel;
          try {
            final imRes = await _client.get<Map<String, dynamic>>(
              '/imoveis/${contrato.imovelId}',
              parser: (raw) => Map<String, dynamic>.from(raw as Map),
            );
            imovel = Imovel.fromJson(imRes.dados ?? {});
          } catch (_) {
            imovel = null;
          }

          items.add(
            AgendaItem(
              checklist: ck,
              contrato: contrato,
              imovel: imovel,
              agendamento: agendamentoMatch,
            ),
          );
        }
      } catch (_) {
        for (final ck in checklists) {
          if (ocultarEncerramento && ck.isEncerramento) continue;
          items.add(AgendaItem(checklist: ck, contrato: contrato));
        }
      }
    }

    items.sort((a, b) {
      final da = a.agendamento?.dataAgendada ??
          a.checklist.dataVistoria ??
          a.checklist.createdAt ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final db = b.agendamento?.dataAgendada ??
          b.checklist.dataVistoria ??
          b.checklist.createdAt ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return da.compareTo(db);
    });
    return items;
  }
}
