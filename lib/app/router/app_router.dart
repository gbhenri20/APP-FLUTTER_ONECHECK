import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/agenda/presentation/pages/agenda_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/mfa_page.dart';
import '../../features/auth/presentation/pages/mfa_setup_page.dart';
import '../../features/checklist/presentation/pages/revisao_page.dart';
import '../../features/checklist/presentation/pages/vistoria_checklist_page.dart';
import '../../features/home/presentation/pages/admin_dashboard_page.dart';
import '../../features/home/presentation/pages/home_shell.dart';
import '../../features/logs/presentation/historico_page.dart';
import '../../features/ocorrencias/presentation/pages/ocorrencias_page.dart';
import '../../features/perfil/presentation/pages/perfil_page.dart';
import '../../features/vistoria/presentation/pages/locatario_vistorias_page.dart';
import '../providers.dart';

final _rootKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/',
    refreshListenable: _AuthListenable(ref),
    redirect: (context, state) {
      final loggingIn = state.matchedLocation == '/login' ||
          state.matchedLocation == '/mfa' ||
          state.matchedLocation == '/mfa-setup';
      final status = auth.status;

      if (status == AuthStatus.unknown) return null;

      if (status != AuthStatus.authenticated) {
        if (auth.pendingMfaToken != null && state.matchedLocation != '/mfa') {
          return '/mfa';
        }
        if (auth.pendingSetupToken != null &&
            state.matchedLocation != '/mfa-setup') {
          return '/mfa-setup';
        }
        if (!loggingIn &&
            auth.pendingMfaToken == null &&
            auth.pendingSetupToken == null) {
          return '/login';
        }
        return null;
      }

      if (loggingIn) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/mfa', builder: (_, __) => const MfaPage()),
      GoRoute(path: '/mfa-setup', builder: (_, __) => const MfaSetupPage()),
      ShellRoute(
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => const RoleHomeRedirect(),
          ),
          GoRoute(path: '/agenda', builder: (_, __) => const AgendaPage()),
          GoRoute(
            path: '/vistoria/:id',
            builder: (_, state) => VistoriaChecklistPage(
              checklistId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/vistoria/:id/revisao',
            builder: (_, state) => RevisaoPage(
              checklistId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/locatario',
            builder: (_, __) => const LocatarioVistoriasPage(),
          ),
          GoRoute(
            path: '/locatario/vistoria/:id',
            builder: (_, state) => LocatarioDetalhePage(
              checklistId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/ocorrencias',
            builder: (_, __) => const OcorrenciasPage(),
          ),
          GoRoute(
            path: '/admin',
            builder: (_, __) => const AdminDashboardPage(),
          ),
          GoRoute(
            path: '/historico',
            builder: (_, __) => const HistoricoPage(),
          ),
          GoRoute(path: '/perfil', builder: (_, __) => const PerfilPage()),
        ],
      ),
    ],
  );
});

class _AuthListenable extends ChangeNotifier {
  _AuthListenable(this.ref) {
    ref.listen<AuthState>(authStateProvider, (_, __) => notifyListeners());
  }
  final Ref ref;
}
