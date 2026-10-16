import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../checklist/domain/checklist_models.dart';

final locatarioVistoriasProvider =
    FutureProvider.autoDispose<List<AgendaItem>>((ref) async {
  final client = ref.watch(dioClientProvider);
  final contratosRes = await client.get<List<Contrato>>(
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
  final items = <AgendaItem>[];
  for (final ct in contratosRes.dados ?? const <Contrato>[]) {
    final checks = await client.get<List<Checklist>>(
      '/contratos/${ct.id}/checklists',
      parser: (raw) {
        final list = raw as List? ?? const [];
        return list
            .whereType<Map>()
            .map((e) => Checklist.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      },
    );
    Imovel? imovel;
    try {
      final im = await client.get<Map<String, dynamic>>(
        '/imoveis/${ct.imovelId}',
        parser: (raw) => Map<String, dynamic>.from(raw as Map),
      );
      imovel = Imovel.fromJson(im.dados ?? {});
    } catch (_) {}
    for (final ck in checks.dados ?? const <Checklist>[]) {
      items.add(AgendaItem(checklist: ck, contrato: ct, imovel: imovel));
    }
  }
  return items;
});

class LocatarioVistoriasPage extends ConsumerWidget {
  const LocatarioVistoriasPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(locatarioVistoriasProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Minhas vistorias')),
      body: async.when(
        loading: () => const OcLoading(),
        error: (e, _) => OcErrorView(
          message: e is AppException ? e.message : 'Erro ao carregar',
          onRetry: () => ref.invalidate(locatarioVistoriasProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const OcEmptyState(
              title: 'Nenhuma vistoria encontrada',
              subtitle: 'Quando houver laudos do seu contrato, eles aparecerão aqui.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(locatarioVistoriasProvider);
              await ref.read(locatarioVistoriasProvider.future);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final item = items[i];
                final ck = item.checklist;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: OcInfoCard(
                    title: item.imovel?.nomeExibicao ?? 'Vistoria',
                    subtitle:
                        '${labelTipoVistoria(ck.tipo)} · ${formatDate(ck.dataVistoria)}',
                    trailing: StatusChip(status: ck.status),
                    onTap: () => context.push('/locatario/vistoria/${ck.id}'),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class LocatarioDetalhePage extends ConsumerStatefulWidget {
  const LocatarioDetalhePage({super.key, required this.checklistId});
  final String checklistId;

  @override
  ConsumerState<LocatarioDetalhePage> createState() =>
      _LocatarioDetalhePageState();
}

class _LocatarioDetalhePageState extends ConsumerState<LocatarioDetalhePage> {
  bool _busy = false;
  final _motivo = TextEditingController();

  @override
  void dispose() {
    _motivo.dispose();
    super.dispose();
  }

  Future<void> _aceitar() async {
    setState(() => _busy = true);
    try {
      await ref.read(checklistRepositoryProvider).aceitar(widget.checklistId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vistoria aceita')),
        );
        ref.invalidate(locatarioVistoriasProvider);
        context.pop();
      }
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _rejeitar() async {
    final motivo = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rejeitar vistoria'),
        content: TextField(
          controller: _motivo,
          decoration: const InputDecoration(
            labelText: 'Motivo da rejeição',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, _motivo.text.trim()),
            child: const Text('Rejeitar'),
          ),
        ],
      ),
    );
    if (motivo == null || motivo.isEmpty) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(checklistRepositoryProvider)
          .rejeitar(widget.checklistId, motivo: motivo);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vistoria rejeitada')),
        );
        ref.invalidate(locatarioVistoriasProvider);
        context.pop();
      }
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: ref.read(checklistRepositoryProvider).getChecklist(widget.checklistId),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(body: OcLoading());
        }
        if (snap.hasError) {
          return Scaffold(
            appBar: AppBar(),
            body: OcErrorView(
              message: snap.error is AppException
                  ? (snap.error as AppException).message
                  : 'Erro',
            ),
          );
        }
        final ck = snap.data!;
        return Scaffold(
          appBar: AppBar(title: const Text('Detalhe da vistoria')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              OcInfoCard(
                title: labelTipoVistoria(ck.tipo),
                subtitle:
                    'Status: ${labelChecklistStatus(ck.status)}\n'
                    'Itens: ${ck.itens.length}',
                trailing: StatusChip(status: ck.status),
              ),
              const SizedBox(height: 16),
              ...ck.itens.map(
                (i) => ListTile(
                  title: Text(i.itemVistoriaId),
                  subtitle: Text(
                    '${labelEstadoItem(i.estado)}'
                    '${i.observacao != null ? ' · ${i.observacao}' : ''}',
                  ),
                ),
              ),
              if (ck.aguardandoAceite) ...[
                const SizedBox(height: 24),
                if (_busy) const LinearProgressIndicator(),
                OcPrimaryButton(
                  label: 'Aceitar vistoria',
                  icon: Icons.check,
                  onPressed: _busy ? null : _aceitar,
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _rejeitar,
                  icon: const Icon(Icons.close),
                  label: const Text('Rejeitar com motivo'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
