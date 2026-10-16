import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers.dart';
import '../../../../core/utils/formatters.dart';
import '../../../auth/domain/user.dart';

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).user;
    final location = GoRouterState.of(context).uri.toString();
    final destinations = _destinationsFor(user?.role);

    var selected = 0;
    for (var i = 0; i < destinations.length; i++) {
      if (location.startsWith(destinations[i].path)) {
        selected = i;
        break;
      }
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected,
        onDestinationSelected: (i) => context.go(destinations[i].path),
        destinations: [
          for (final d in destinations)
            NavigationDestination(icon: Icon(d.icon), label: d.label),
        ],
      ),
    );
  }

  List<_NavDest> _destinationsFor(UserRole? role) {
    switch (role) {
      case UserRole.vistoriador:
        return const [
          _NavDest('/agenda', 'Agenda', Icons.calendar_month_outlined),
          _NavDest('/historico', 'Histórico', Icons.history),
          _NavDest('/perfil', 'Perfil', Icons.person_outline),
        ];
      case UserRole.locatario:
        return const [
          _NavDest('/locatario', 'Vistorias', Icons.home_work_outlined),
          _NavDest('/ocorrencias', 'Ocorrências', Icons.report_problem_outlined),
          _NavDest('/historico', 'Histórico', Icons.history),
          _NavDest('/perfil', 'Perfil', Icons.person_outline),
        ];
      case UserRole.admin:
      case UserRole.gestor:
        return const [
          _NavDest('/admin', 'Painel', Icons.dashboard_outlined),
          _NavDest('/agenda', 'Vistorias', Icons.assignment_outlined),
          _NavDest('/historico', 'Histórico', Icons.history),
          _NavDest('/perfil', 'Perfil', Icons.person_outline),
        ];
      default:
        return const [
          _NavDest('/perfil', 'Perfil', Icons.person_outline),
        ];
    }
  }
}

class _NavDest {
  const _NavDest(this.path, this.label, this.icon);
  final String path;
  final String label;
  final IconData icon;
}

class RoleHomeRedirect extends ConsumerWidget {
  const RoleHomeRedirect({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).user;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      switch (user?.role) {
        case UserRole.vistoriador:
          context.go('/agenda');
        case UserRole.locatario:
          context.go('/locatario');
        case UserRole.admin:
        case UserRole.gestor:
          context.go('/admin');
        default:
          context.go('/perfil');
      }
    });
    return Scaffold(
      body: Center(
        child: Text(
          user == null
              ? 'Carregando...'
              : 'Olá, ${user.nome} (${labelRole(user.roleRaw)})',
        ),
      ),
    );
  }
}
