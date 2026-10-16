import 'package:flutter_test/flutter_test.dart';
import 'package:one_check/core/utils/formatters.dart';
import 'package:one_check/features/checklist/domain/checklist_models.dart';

void main() {
  group('Checklist', () {
    test('parseia resposta da API e regras de edição', () {
      final ck = Checklist.fromJson({
        'id': 'ck1',
        'contrato_id': 'ct1',
        'vistoriador_id': 'v1',
        'tipo': 'inicial',
        'status': 'em_preenchimento',
        'data_vistoria': '2026-10-16',
        'itens': [
          {
            'id': 'i1',
            'checklist_id': 'ck1',
            'comodo_id': 'c1',
            'item_vistoria_id': 'iv1',
            'estado': 'bom',
            'observacao': 'ok',
            'fotos': [],
          },
          {
            'id': 'i2',
            'checklist_id': 'ck1',
            'comodo_id': 'c1',
            'item_vistoria_id': 'iv2',
            'estado': null,
            'fotos': [],
          },
        ],
        'comodos': [
          {'id': 'c1', 'imovel_id': 'im1', 'tipo': 'sala', 'nome': 'Sala'},
        ],
      });

      expect(ck.podeEditar, isTrue);
      expect(ck.itensPreenchidos, 1);
      expect(ck.isEncerramento, isFalse);
      expect(labelChecklistStatus(ck.status), 'Em preenchimento');
      expect(labelEstadoItem('otimo'), 'Ótimo');
    });

    test('bloqueia edição após submissão', () {
      final ck = Checklist.fromJson({
        'id': 'ck2',
        'contrato_id': 'ct1',
        'vistoriador_id': 'v1',
        'tipo': 'encerramento',
        'status': 'pendente_aceite',
      });
      expect(ck.podeEditar, isFalse);
      expect(ck.aguardandoAceite, isTrue);
      expect(ck.isEncerramento, isTrue);
    });
  });
}
