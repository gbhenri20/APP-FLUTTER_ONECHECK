
import 'dart:convert';

import '../../../core/errors/app_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/security/token_storage.dart';
import '../../../core/storage/local_database.dart';
import '../domain/auth_session.dart';
import '../domain/user.dart';

class AuthRepository {
  AuthRepository({
    required DioClient client,
    required TokenStorage tokenStorage,
    required LocalDatabase localDb,
  })  : _client = client,
        _tokens = tokenStorage,
        _localDb = localDb;

  final DioClient _client;
  final TokenStorage _tokens;
  final LocalDatabase _localDb;

  Future<AuthOutcome> login({required String email, required String senha}) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email.trim(), 'senha': senha},
      skipAuth: true,
      skipRefresh: true,
      parser: (raw) => Map<String, dynamic>.from(raw as Map),
    );
    final dados = res.dados ?? {};
    await _localDb.appendOpLog({
      'tipo': 'login',
      'resultado': 'ok',
      'detalhe': email.trim(),
    });
    return _parseAuthOutcome(dados);
  }

  Future<AuthOutcome> verifyMfa({
    required String tempToken,
    required String codigo,
  }) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/auth/mfa/verify',
      data: {'temp_token': tempToken, 'codigo': codigo.trim()},
      skipAuth: true,
      skipRefresh: true,
      parser: (raw) => Map<String, dynamic>.from(raw as Map),
    );
    return _parseAuthOutcome(res.dados ?? {});
  }

  Future<MfaSetupData> setupMfaLogin(String tempToken) async {
    final res = await _client.get<Map<String, dynamic>>(
      '/auth/mfa/setup-login',
      query: {'temp_token': tempToken},
      skipAuth: true,
      parser: (raw) => Map<String, dynamic>.from(raw as Map),
    );
    return MfaSetupData.fromJson(res.dados ?? {});
  }

  Future<AuthOutcome> activateMfaLogin({
    required String tempToken,
    required String codigo,
  }) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/auth/mfa/activate-login',
      data: {'temp_token': tempToken, 'codigo': codigo.trim()},
      skipAuth: true,
      skipRefresh: true,
      parser: (raw) => Map<String, dynamic>.from(raw as Map),
    );
    return _parseAuthOutcome(res.dados ?? {});
  }

  Future<void> persistAuthenticated(AuthAuthenticated session) async {
    await _tokens.saveSession(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      userJson: jsonEncode(session.usuario.toJson()),
    );
  }

  Future<User?> restoreSession() async {
    final access = await _tokens.readAccessToken();
    final refresh = await _tokens.readRefreshToken();
    final userJson = await _tokens.readUserJson();
    if (access == null || refresh == null || userJson == null) {
      return null;
    }
    try {
      final me = await _client.get<Map<String, dynamic>>(
        '/usuarios/me',
        parser: (raw) => Map<String, dynamic>.from(raw as Map),
      );
      final user = User.fromJson(me.dados ?? jsonDecode(userJson) as Map<String, dynamic>);
      await _tokens.saveSession(
        accessToken: access,
        refreshToken: refresh,
        userJson: jsonEncode(user.toJson()),
      );
      return user;
    } on AppException catch (e) {
      if (e.isUnauthorized) {
        await _tokens.clearSession();
        return null;
      }
      // Offline: usa último usuário conhecido; rascunhos permanecem.
      return User.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
    }
  }

  Future<User> fetchMe() async {
    final res = await _client.get<Map<String, dynamic>>(
      '/usuarios/me',
      parser: (raw) => Map<String, dynamic>.from(raw as Map),
    );
    return User.fromJson(res.dados ?? {});
  }

  Future<void> logout() async {
    final refresh = await _tokens.readRefreshToken();
    try {
      await _client.post(
        '/auth/logout',
        data: refresh != null ? {'refresh_token': refresh} : null,
        skipRefresh: true,
      );
    } catch (_) {
      // Logout local mesmo se backend falhar.
    } finally {
      await _tokens.clearSession();
      await _localDb.appendOpLog({
        'tipo': 'logout',
        'resultado': 'ok',
      });
    }
  }

  AuthOutcome _parseAuthOutcome(Map<String, dynamic> dados) {
    if (dados['mfa_required'] == true) {
      final temp = (dados['temp_token'] ?? dados['mfa_token']) as String?;
      if (temp == null) {
        throw const AppException('Token MFA ausente na resposta');
      }
      return AuthMfaRequired(tempToken: temp);
    }
    if (dados['mfa_setup_required'] == true) {
      final temp = (dados['temp_token'] ?? dados['mfa_token']) as String?;
      if (temp == null) {
        throw const AppException('Token de setup MFA ausente');
      }
      return AuthMfaSetupRequired(tempToken: temp);
    }
    final access = dados['access_token'] as String?;
    final refresh = dados['refresh_token'] as String?;
    final usuarioRaw = dados['usuario'];
    if (access == null || refresh == null || usuarioRaw is! Map) {
      throw const AppException('Resposta de autenticação incompleta');
    }
    return AuthAuthenticated(
      accessToken: access,
      refreshToken: refresh,
      usuario: User.fromJson(Map<String, dynamic>.from(usuarioRaw)),
    );
  }
}
