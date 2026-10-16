
import 'package:equatable/equatable.dart';

enum UserRole { admin, gestor, vistoriador, locatario, unknown }

UserRole roleFromString(String? value) {
  switch (value) {
    case 'admin':
      return UserRole.admin;
    case 'gestor':
      return UserRole.gestor;
    case 'vistoriador':
      return UserRole.vistoriador;
    case 'locatario':
      return UserRole.locatario;
    default:
      return UserRole.unknown;
  }
}

class User extends Equatable {
  const User({
    required this.id,
    required this.nome,
    required this.email,
    required this.role,
    this.mfaEnabled,
    this.mfaConfigurado,
  });

  final String id;
  final String nome;
  final String email;
  final UserRole role;
  final bool? mfaEnabled;
  final bool? mfaConfigurado;

  String get roleRaw {
    switch (role) {
      case UserRole.admin:
        return 'admin';
      case UserRole.gestor:
        return 'gestor';
      case UserRole.vistoriador:
        return 'vistoriador';
      case UserRole.locatario:
        return 'locatario';
      case UserRole.unknown:
        return 'unknown';
    }
  }

  bool get isAdmin => role == UserRole.admin;
  bool get isGestor => role == UserRole.gestor || role == UserRole.admin;
  bool get isVistoriador => role == UserRole.vistoriador;
  bool get isLocatario => role == UserRole.locatario;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      nome: json['nome'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: roleFromString(json['role'] as String?),
      mfaEnabled: json['mfa_enabled'] as bool?,
      mfaConfigurado: json['mfa_configurado'] as bool?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'email': email,
        'role': roleRaw,
        if (mfaEnabled != null) 'mfa_enabled': mfaEnabled,
        if (mfaConfigurado != null) 'mfa_configurado': mfaConfigurado,
      };

  @override
  List<Object?> get props => [id, email, role];
}
