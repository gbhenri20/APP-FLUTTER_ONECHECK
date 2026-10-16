
import 'package:equatable/equatable.dart';

class Problema extends Equatable {
  const Problema({
    required this.id,
    required this.contratoId,
    required this.titulo,
    required this.status,
    this.comodoId,
    this.descricao,
    this.fotoUrl,
    this.prioridade,
    this.createdAt,
    this.atualizacoes = const [],
  });

  final String id;
  final String contratoId;
  final String titulo;
  final String status;
  final String? comodoId;
  final String? descricao;
  final String? fotoUrl;
  final String? prioridade;
  final DateTime? createdAt;
  final List<AtualizacaoProblema> atualizacoes;

  factory Problema.fromJson(Map<String, dynamic> json) {
    final at = json['atualizacoes'] as List? ?? const [];
    return Problema(
      id: json['id'] as String,
      contratoId: json['contrato_id'] as String? ?? '',
      titulo: json['titulo'] as String? ?? '',
      status: json['status'] as String? ?? '',
      comodoId: json['comodo_id'] as String?,
      descricao: json['descricao'] as String?,
      fotoUrl: json['foto_url'] as String?,
      prioridade: json['prioridade'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      atualizacoes: at
          .whereType<Map>()
          .map((e) => AtualizacaoProblema.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [id, status];
}

class AtualizacaoProblema extends Equatable {
  const AtualizacaoProblema({
    required this.id,
    required this.descricao,
    this.fotoUrl,
    this.createdAt,
  });

  final String id;
  final String descricao;
  final String? fotoUrl;
  final DateTime? createdAt;

  factory AtualizacaoProblema.fromJson(Map<String, dynamic> json) {
    return AtualizacaoProblema(
      id: json['id'] as String,
      descricao: json['descricao'] as String? ?? '',
      fotoUrl: json['foto_url'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }

  @override
  List<Object?> get props => [id];
}
