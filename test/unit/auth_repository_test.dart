import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:one_check/core/config/app_config.dart';
import 'package:one_check/core/errors/app_exception.dart';
import 'package:one_check/core/network/dio_client.dart';
import 'package:one_check/core/security/token_storage.dart';
import 'package:one_check/core/storage/local_database.dart';
import 'package:one_check/features/auth/data/auth_repository.dart';
import 'package:one_check/features/auth/domain/auth_session.dart';

class _MemoryTokenStorage extends TokenStorage {
  final Map<String, String> _data = {};

  @override
  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required String userJson,
  }) async {
    _data['a'] = accessToken;
    _data['r'] = refreshToken;
    _data['u'] = userJson;
  }

  @override
  Future<void> updateTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _data['a'] = accessToken;
    _data['r'] = refreshToken;
  }

  @override
  Future<String?> readAccessToken() async => _data['a'];
  @override
  Future<String?> readRefreshToken() async => _data['r'];
  @override
  Future<String?> readUserJson() async => _data['u'];
  @override
  Future<void> clearSession() async => _data.clear();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Dio dio;
  late DioAdapter adapter;
  late AuthRepository repo;

  setUpAll(() async {
    await LocalDatabase.init(testPath: '/tmp/one_check_hive_auth');
  });

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'http://test/api/v1'));
    adapter = DioAdapter(dio: dio);
    final client = DioClient(
      config: AppConfig.forTests(baseUrl: 'http://test'),
      tokenStorage: _MemoryTokenStorage(),
      dio: dio,
    );
    repo = AuthRepository(
      client: client,
      tokenStorage: _MemoryTokenStorage(),
      localDb: localDatabase,
    );
  });

  test('login com credenciais inválidas lança AppException', () async {
    adapter.onPost(
      '/auth/login',
      (server) => server.reply(200, {
        'sucesso': false,
        'erro': 'Credenciais inválidas',
      }),
      data: Matchers.any,
    );

    expect(
      () => repo.login(email: 'x@y.com', senha: 'errada'),
      throwsA(isA<AppException>()),
    );
  });

  test('login exige MFA quando API retorna mfa_required', () async {
    adapter.onPost(
      '/auth/login',
      (server) => server.reply(200, {
        'sucesso': true,
        'dados': {
          'mfa_required': true,
          'temp_token': 'temp-abc',
        },
      }),
      data: Matchers.any,
    );

    final outcome =
        await repo.login(email: 'v@onecheck.local', senha: 'vistor123');
    expect(outcome, isA<AuthMfaRequired>());
    expect((outcome as AuthMfaRequired).tempToken, 'temp-abc');
  });

  test('login exige setup MFA no primeiro acesso', () async {
    adapter.onPost(
      '/auth/login',
      (server) => server.reply(200, {
        'sucesso': true,
        'dados': {
          'mfa_setup_required': true,
          'temp_token': 'setup-xyz',
        },
      }),
      data: Matchers.any,
    );

    final outcome =
        await repo.login(email: 'admin@onecheck.local', senha: 'admin123');
    expect(outcome, isA<AuthMfaSetupRequired>());
  });

  test('MFA verify retorna sessão autenticada', () async {
    adapter.onPost(
      '/auth/mfa/verify',
      (server) => server.reply(200, {
        'sucesso': true,
        'dados': {
          'access_token': 'acc',
          'refresh_token': 'ref',
          'usuario': {
            'id': '1',
            'nome': 'Vistoriador',
            'email': 'vistoriador@onecheck.local',
            'role': 'vistoriador',
          },
        },
      }),
      data: Matchers.any,
    );

    final outcome = await repo.verifyMfa(tempToken: 't', codigo: '123456');
    expect(outcome, isA<AuthAuthenticated>());
    final auth = outcome as AuthAuthenticated;
    expect(auth.usuario.role.name, 'vistoriador');
    expect(auth.accessToken, 'acc');
  });

  test('código MFA inválido propaga erro da API', () async {
    adapter.onPost(
      '/auth/mfa/verify',
      (server) => server.reply(200, {
        'sucesso': false,
        'erro': 'Código MFA inválido',
      }),
      data: {
        'temp_token': 't',
        'codigo': '000000',
      },
    );

    expect(
      () => repo.verifyMfa(tempToken: 't', codigo: '000000'),
      throwsA(isA<AppException>()),
    );
  });
}
