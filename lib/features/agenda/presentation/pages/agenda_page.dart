import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../checklist/domain/checklist_models.dart';
import '../providers/agenda_providers.dart';

class AgendaPage extends ConsumerWidget {
  const AgendaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(agendaProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda de vistorias'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: () => ref.invalidate(agendaProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: async.when(
        loading: () => const OcLoading(message: 'Carregando agenda...'),
        error: (e, _) {
          final msg = e is AppException ? e.message : 'Falha ao carregar agenda';
          return OcErrorView(
            message: msg,
            onRetry: () => ref.invalidate(agendaProvider),
          );
        },
        data: (items) {
          final pendentes =
              items.where((i) => i.checklist.pendente).toList();
          final enviadas =
              items.where((i) => !i.checklist.pendente).toList();

          if (items.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(agendaProvider),
              child: ListView(
                children: const [
                  SizedBox(height: 120),
                  OcEmptyState(
                    title: 'Nenhuma vistoria na agenda',
                    subtitle:
                        'Quando houver checklists atribuídos a você, eles aparecerão aqui.',
                    icon: Icons.event_available_outlined,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(agendaProvider);
              await ref.read(agendaProvider.future);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Pendentes (${pendentes.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (pendentes.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text('Nenhuma vistoria pendente.'),
                  )
                else
                  ...pendentes.map((item) => _AgendaTile(item: item)),
                const SizedBox(height: 16),
                Text(
                  'Enviadas (${enviadas.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (enviadas.isEmpty)
                  const Text('Nenhuma vistoria enviada ainda.')
                else
                  ...enviadas.map((item) => _AgendaTile(item: item)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AgendaTile extends StatelessWidget {
  const _AgendaTile({required this.item});
  final AgendaItem item;

  @override
  Widget build(BuildContext context) {
    final ck = item.checklist;
    final imovel = item.imovel;
    final data = item.agendamento?.dataAgendada ?? ck.dataVistoria;
    final editable = ck.podeEditar;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: OcInfoCard(
        title: imovel?.nomeExibicao ?? 'Contrato ${item.contrato.id.substring(0, 8)}…',
        subtitle:
            '${imovel?.endereco?.linhaCompleta ?? 'Endereço indisponível'}\n'
            '${labelTipoVistoria(ck.tipo)} · ${formatDateTime(data)}',
        trailing: StatusChip(status: ck.status),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
          child: Icon(
            editable ? Icons.assignment_outlined : Icons.lock_outline,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        onTap: () {
          if (!editable) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Esta vistoria já foi enviada e não pode ser reaberta para edição.',
                ),
              ),
            );
            context.push('/vistoria/${ck.id}/revisao');
            return;
          }
          context.push('/vistoria/${ck.id}');
        },
      ),
    );
  }
}
