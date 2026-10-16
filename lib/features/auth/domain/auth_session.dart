
import 'package:equatable/equatable.dart';

import 'user.dart';

sealed class AuthOutcome extends Equatable {
  const AuthOutcome();
  @override
  List<Object?> get props => [];
}

class AuthAuthenticated extends AuthOutcome {
  const AuthAuthenticated({
    required this.accessToken,
    required this.refreshToken,
    required this.usuario,
  });
  final String accessToken;
  final String refreshToken;
  final User usuario;
  @override
  List<Object?> get props => [accessToken, refreshToken, usuario];
}

class AuthMfaRequired extends AuthOutcome {
  const AuthMfaRequired({required this.tempToken});
  final String tempToken;
  @override
  List<Object?> get props => [tempToken];
}

class AuthMfaSetupRequired extends AuthOutcome {
  const AuthMfaSetupRequired({required this.tempToken});
  final String tempToken;
  @override
  List<Object?> get props => [tempToken];
}

class MfaSetupData {
  const MfaSetupData({
    required this.secret,
    required this.provisioningUri,
    required this.qrUrl,
  });

  final String secret;
  final String provisioningUri;
  final String qrUrl;

  factory MfaSetupData.fromJson(Map<String, dynamic> json) {
    return MfaSetupData(
      secret: json['secret'] as String? ?? '',
      provisioningUri: (json['provisioning_uri'] ?? json['otpauth_uri']) as String? ?? '',
      qrUrl: json['qr_url'] as String? ?? '',
    );
  }
}
