import 'package:flutter_test/flutter_test.dart';
import 'package:one_check/features/auth/domain/auth_session.dart';
import 'package:one_check/features/auth/domain/user.dart';

void main() {
  group('UserRole', () {
    test('mapeia roles da API', () {
      expect(roleFromString('admin'), UserRole.admin);
      expect(roleFromString('gestor'), UserRole.gestor);
      expect(roleFromString('vistoriador'), UserRole.vistoriador);
      expect(roleFromString('locatario'), UserRole.locatario);
      expect(roleFromString('outro'), UserRole.unknown);
    });

    test('serializa usuário', () {
      const user = User(
        id: '1',
        nome: 'Ana',
        email: 'ana@onecheck.local',
        role: UserRole.vistoriador,
      );
      final json = user.toJson();
      expect(json['role'], 'vistoriador');
      expect(User.fromJson(json).email, 'ana@onecheck.local');
    });
  });

  group('AuthOutcome', () {
    test('distingue MFA e autenticação completa', () {
      const mfa = AuthMfaRequired(tempToken: 'tmp');
      const setup = AuthMfaSetupRequired(tempToken: 'tmp2');
      final auth = AuthAuthenticated(
        accessToken: 'a',
        refreshToken: 'r',
        usuario: const User(
          id: '1',
          nome: 'A',
          email: 'a@b.com',
          role: UserRole.admin,
        ),
      );
      expect(mfa, isA<AuthMfaRequired>());
      expect(setup, isA<AuthMfaSetupRequired>());
      expect(auth, isA<AuthAuthenticated>());
    });
  });
}
