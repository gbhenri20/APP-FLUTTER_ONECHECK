import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/network/dio_client.dart';
import '../core/security/token_storage.dart';
import '../core/storage/local_database.dart';
import '../core/utils/image_compressor.dart';
import '../features/agenda/data/agenda_repository.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/domain/auth_session.dart';
import '../features/auth/domain/user.dart';
import '../features/checklist/data/checklist_repository.dart';
import '../features/ocorrencias/data/problemas_repository.dart';

final appConfigProvider = Provider<AppConfig>((ref) {
  throw UnimplementedError('AppConfig deve ser sobrescrito no ProviderScope');
});

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final localDatabaseProvider = Provider<LocalDatabase>((ref) => localDatabase);

final sessionExpiredProvider = StateProvider<int>((ref) => 0);

/// Evita ciclo dio ↔ auth: o callback é ligado após a criação do AuthController.
final sessionExpiredCallbackProvider = Provider<void Function()>((ref) {
  return () {
    ref.read(sessionExpiredProvider.notifier).state++;
  };
});

final dioClientProvider = Provider<DioClient>((ref) {
  final config = ref.watch(appConfigProvider);
  final storage = ref.watch(tokenStorageProvider);
  return DioClient(
    config: config,
    tokenStorage: storage,
    onSessionExpired: () {
      ref.read(sessionExpiredCallbackProvider)();
    },
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    client: ref.watch(dioClientProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
    localDb: ref.watch(localDatabaseProvider),
  );
});

final agendaRepositoryProvider = Provider<AgendaRepository>((ref) {
  return AgendaRepository(ref.watch(dioClientProvider));
});

final checklistRepositoryProvider = Provider<ChecklistRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  return ChecklistRepository(
    client: ref.watch(dioClientProvider),
    localDb: ref.watch(localDatabaseProvider),
    compressor: ImageCompressor(
      maxWidth: config.imageMaxWidth,
      quality: config.imageQuality,
    ),
  );
});

final problemasRepositoryProvider = Provider<ProblemasRepository>((ref) {
  return ProblemasRepository(ref.watch(dioClientProvider));
});

enum AuthStatus { unknown, unauthenticated, authenticated }

class AuthState {
  const AuthState({
    required this.status,
    this.user,
    this.pendingMfaToken,
    this.pendingSetupToken,
  });

  final AuthStatus status;
  final User? user;
  final String? pendingMfaToken;
  final String? pendingSetupToken;

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null;
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repo)
      : super(const AuthState(status: AuthStatus.unknown));

  final AuthRepository _repo;

  Future<void> bootstrap() async {
    final user = await _repo.restoreSession();
    if (user == null) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    } else {
      state = AuthState(status: AuthStatus.authenticated, user: user);
    }
  }

  /// Retorna: null = autenticado; 'mfa'; 'setup'; ou mensagem de erro.
  Future<String?> login(String email, String senha) async {
    final outcome = await _repo.login(email: email, senha: senha);
    return _applyOutcome(outcome);
  }

  Future<String?> verifyMfa(String codigo) async {
    final token = state.pendingMfaToken;
    if (token == null) return 'Sessão MFA inválida';
    final outcome =
        await _repo.verifyMfa(tempToken: token, codigo: codigo);
    return _applyOutcome(outcome);
  }

  Future<String?> activateSetup(String codigo) async {
    final token = state.pendingSetupToken;
    if (token == null) return 'Sessão de setup MFA inválida';
    final outcome =
        await _repo.activateMfaLogin(tempToken: token, codigo: codigo);
    return _applyOutcome(outcome);
  }

  Future<MfaSetupData> loadSetupData() {
    final token = state.pendingSetupToken;
    if (token == null) {
      throw StateError('Setup MFA não iniciado');
    }
    return _repo.setupMfaLogin(token);
  }

  Future<String?> _applyOutcome(AuthOutcome outcome) async {
    switch (outcome) {
      case AuthMfaRequired(:final tempToken):
        state = AuthState(
          status: AuthStatus.unauthenticated,
          pendingMfaToken: tempToken,
        );
        return 'mfa';
      case AuthMfaSetupRequired(:final tempToken):
        state = AuthState(
          status: AuthStatus.unauthenticated,
          pendingSetupToken: tempToken,
        );
        return 'setup';
      case AuthAuthenticated():
        await _repo.persistAuthenticated(outcome);
        state = AuthState(
          status: AuthStatus.authenticated,
          user: outcome.usuario,
        );
        return null;
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void forceLogoutLocal() {
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authStateProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  final controller = AuthController(ref.watch(authRepositoryProvider));
  // Liga o callback de sessão expirada sem criar ciclo de providers.
  ref.listen<int>(sessionExpiredProvider, (prev, next) {
    if (prev != null && next > prev) {
      controller.forceLogoutLocal();
    }
  });
  return controller;
});
