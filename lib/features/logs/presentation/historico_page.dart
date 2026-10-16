import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_widgets.dart';

class HistoricoPage extends ConsumerStatefulWidget {
  const HistoricoPage({super.key});

  @override
  ConsumerState<HistoricoPage> createState() => _HistoricoPageState();
}

class _HistoricoPageState extends ConsumerState<HistoricoPage> {
  late List<Map<String, dynamic>> _logs;

  @override
  void initState() {
    super.initState();
    _logs = ref.read(localDatabaseProvider).readOpLogs();
  }

  void _reload() {
    setState(() {
      _logs = ref.read(localDatabaseProvider).readOpLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico local'),
        actions: [
          IconButton(
            tooltip: 'Limpar histórico local',
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Limpar histórico?'),
                  content: const Text(
                    'Remove apenas o log local do aparelho. '
                    'Dados já enviados ao servidor permanecem intactos.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancelar'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Limpar'),
                    ),
                  ],
                ),
              );
              if (ok == true) {
                await ref.read(localDatabaseProvider).clearOpLogs();
                _reload();
              }
            },
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        ],
      ),
      body: _logs.isEmpty
          ? const OcEmptyState(
              title: 'Nenhuma operação registrada',
              subtitle: 'Envios, salvamentos e erros aparecerão aqui.',
            )
          : RefreshIndicator(
              onRefresh: () async => _reload(),
              child: ListView.separated(
                itemCount: _logs.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final log = _logs[i];
                  final at = DateTime.tryParse(log['at'] as String? ?? '');
                  return ListTile(
                    title: Text('${log['tipo'] ?? 'operação'}'),
                    subtitle: Text(
                      '${log['resultado'] ?? ''} · ${log['detalhe'] ?? ''}\n'
                      '${formatDateTime(at)}',
                    ),
                    isThreeLine: true,
                    leading: Icon(
                      (log['resultado'] == 'ok')
                          ? Icons.check_circle_outline
                          : Icons.error_outline,
                    ),
                  );
                },
              ),
            ),
    );
  }
}
