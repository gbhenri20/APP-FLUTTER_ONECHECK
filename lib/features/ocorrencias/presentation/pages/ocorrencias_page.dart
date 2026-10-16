import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../checklist/domain/checklist_models.dart';
import '../../domain/problema.dart';

final ocorrenciasProvider =
    FutureProvider.autoDispose<List<Problema>>((ref) async {
  final client = ref.watch(dioClientProvider);
  final contratos = await client.get<List<Contrato>>(
    '/contratos',
    query: {'por_pagina': 50},
    parser: (raw) {
      final list = raw as List? ?? const [];
      return list
          .whereType<Map>()
          .map((e) => Contrato.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    },
  );
  final all = <Problema>[];
  final repo = ref.watch(problemasRepositoryProvider);
  for (final ct in contratos.dados ?? const <Contrato>[]) {
    try {
      all.addAll(await repo.listByContrato(ct.id));
    } catch (_) {}
  }
  return all;
});

class OcorrenciasPage extends ConsumerStatefulWidget {
  const OcorrenciasPage({super.key});

  @override
  ConsumerState<OcorrenciasPage> createState() => _OcorrenciasPageState();
}

class _OcorrenciasPageState extends ConsumerState<OcorrenciasPage> {
  Future<void> _nova() async {
    final titulo = TextEditingController();
    final desc = TextEditingController();
    final client = ref.read(dioClientProvider);
    final contratos = await client.get<List<Contrato>>(
      '/contratos',
      parser: (raw) {
        final list = raw as List? ?? const [];
        return list
            .whereType<Map>()
            .map((e) => Contrato.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      },
    );
    final ativos = (contratos.dados ?? [])
        .where((c) => c.status == 'ativo')
        .toList();
    if (!mounted) return;
    if (ativos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum contrato ativo disponível')),
      );
      return;
    }
    final contratoId = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nova ocorrência'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titulo,
              decoration: const InputDecoration(labelText: 'Título'),
            ),
            TextField(
              controller: desc,
              decoration: const InputDecoration(labelText: 'Descrição'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ativos.first.id),
            child: const Text('Registrar'),
          ),
        ],
      ),
    );
    if (contratoId == null) return;
    try {
      await ref.read(problemasRepositoryProvider).criar(
            contratoId: contratoId,
            titulo: titulo.text.trim().isEmpty ? 'Ocorrência' : titulo.text.trim(),
            descricao: desc.text.trim().isEmpty ? 'Sem descrição' : desc.text.trim(),
          );
      ref.invalidate(ocorrenciasProvider);
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(ocorrenciasProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Ocorrências')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _nova,
        icon: const Icon(Icons.add),
        label: const Text('Registrar'),
      ),
      body: async.when(
        loading: () => const OcLoading(),
        error: (e, _) => OcErrorView(
          message: e is AppException ? e.message : 'Erro',
          onRetry: () => ref.invalidate(ocorrenciasProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const OcEmptyState(
              title: 'Nenhuma ocorrência',
              subtitle: 'Registre problemas do imóvel pelo botão abaixo.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final p = items[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: OcInfoCard(
                  title: p.titulo,
                  subtitle: '${p.status} · ${p.descricao ?? ''}',
                ),
              );
            },
          );
        },
      ),
    );
  }
}
