import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/app_widgets.dart';

final dashboardProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final res = await ref.watch(dioClientProvider).get<Map<String, dynamic>>(
        '/dashboard',
        parser: (raw) => Map<String, dynamic>.from(raw as Map),
      );
  return res.dados ?? {};
});

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dashboardProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel One Check'),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(dashboardProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: async.when(
        loading: () => const OcLoading(),
        error: (e, _) => OcErrorView(
          message: e is AppException ? e.message : 'Erro ao carregar painel',
          onRetry: () => ref.invalidate(dashboardProvider),
        ),
        data: (data) {
          final cards = <MapEntry<String, String>>[
            MapEntry('Imóveis locados', '${data['imoveis_locados'] ?? data['imoveisLocados'] ?? '—'}'),
            MapEntry('Checklists pendentes', '${data['checklists_pendentes'] ?? data['checklistsPendentes'] ?? '—'}'),
            MapEntry('Problemas abertos', '${data['problemas_abertos'] ?? data['problemasAbertos'] ?? '—'}'),
            MapEntry('Vistorias agendadas', '${data['vistorias_agendadas'] ?? data['agendamentos'] ?? '—'}'),
          ];
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(dashboardProvider);
              await ref.read(dashboardProvider.future);
            },
            child: GridView.count(
              padding: const EdgeInsets.all(16),
              crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 4 : 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                for (final c in cards)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          c.key,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          c.value,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
