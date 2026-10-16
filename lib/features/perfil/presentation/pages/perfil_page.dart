import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_widgets.dart';

class PerfilPage extends ConsumerWidget {
  const PerfilPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).user;
    final config = ref.watch(appConfigProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          OcInfoCard(
            title: user?.nome ?? 'Usuário',
            subtitle: '${user?.email ?? ''}\n${labelRole(user?.roleRaw ?? '')}',
            leading: CircleAvatar(
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
              child: Text(
                (user?.nome.isNotEmpty == true ? user!.nome[0] : '?')
                    .toUpperCase(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.cloud_outlined),
            title: const Text('Ambiente da API'),
            subtitle: Text('${config.environment} · ${config.apiRoot}'),
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Histórico local de operações'),
            onTap: () => context.push('/historico'),
          ),
          const SizedBox(height: 24),
          OcPrimaryButton(
            label: 'Sair',
            icon: Icons.logout,
            onPressed: () async {
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}
