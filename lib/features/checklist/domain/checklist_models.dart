
import 'package:equatable/equatable.dart';

class Endereco extends Equatable {
  const Endereco({
    this.rua,
    this.numero,
    this.complemento,
    this.bairro,
    this.cidade,
    this.estado,
    this.cep,
  });

  final String? rua;
  final String? numero;
  final String? complemento;
  final String? bairro;
  final String? cidade;
  final String? estado;
  final String? cep;

  String get linhaCompleta {
    final parts = <String>[
      if (rua != null && rua!.isNotEmpty) rua!,
      if (numero != null && numero!.isNotEmpty) numero!,
      if (bairro != null && bairro!.isNotEmpty) bairro!,
      if (cidade != null && cidade!.isNotEmpty) cidade!,
      if (estado != null && estado!.isNotEmpty) estado!,
    ];
    return parts.isEmpty ? 'Endereço não informado' : parts.join(', ');
  }

  factory Endereco.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const Endereco();
    return Endereco(
      rua: (json['rua'] ?? json['logradouro']) as String?,
      numero: json['numero'] as String?,
      complemento: json['complemento'] as String?,
      bairro: json['bairro'] as String?,
      cidade: json['cidade'] as String?,
      estado: json['estado'] as String?,
      cep: json['cep'] as String?,
    );
  }

  @override
  List<Object?> get props => [rua, numero, cidade];
}

class Imovel extends Equatable {
  const Imovel({
    required this.id,
    this.codigo,
    this.titulo,
    this.tipo,
    this.status,
    this.endereco,
  });

  final String id;
  final String? codigo;
  final String? titulo;
  final String? tipo;
  final String? status;
  final Endereco? endereco;

  String get nomeExibicao =>
      (titulo?.isNotEmpty == true ? titulo! : null) ??
      (codigo?.isNotEmpty == true ? codigo! : null) ??
      'Imóvel';

  factory Imovel.fromJson(Map<String, dynamic> json) {
    return Imovel(
      id: json['id'] as String,
      codigo: json['codigo'] as String?,
      titulo: json['titulo'] as String?,
      tipo: json['tipo'] as String?,
      status: json['status'] as String?,
      endereco: json['endereco'] is Map
          ? Endereco.fromJson(Map<String, dynamic>.from(json['endereco'] as Map))
          : null,
    );
  }

  @override
  List<Object?> get props => [id];
}

class Comodo extends Equatable {
  const Comodo({
    required this.id,
    required this.imovelId,
    required this.tipo,
    this.descricao,
    this.nome,
  });

  final String id;
  final String imovelId;
  final String tipo;
  final String? descricao;
  final String? nome;

  String get nomeExibicao =>
      (nome?.isNotEmpty == true ? nome! : null) ??
      (descricao?.isNotEmpty == true ? descricao! : null) ??
      tipo;

  factory Comodo.fromJson(Map<String, dynamic> json) {
    return Comodo(
      id: json['id'] as String,
      imovelId: json['imovel_id'] as String? ?? '',
      tipo: json['tipo'] as String? ?? '',
      descricao: json['descricao'] as String?,
      nome: json['nome'] as String?,
    );
  }

  @override
  List<Object?> get props => [id];
}

class ItemVistoriaCatalogo extends Equatable {
  const ItemVistoriaCatalogo({
    required this.id,
    required this.nome,
    this.categoria,
  });

  final String id;
  final String nome;
  final String? categoria;

  factory ItemVistoriaCatalogo.fromJson(Map<String, dynamic> json) {
    return ItemVistoriaCatalogo(
      id: json['id'] as String,
      nome: json['nome'] as String? ?? '',
      categoria: json['categoria'] as String?,
    );
  }

  @override
  List<Object?> get props => [id];
}

class FotoItem extends Equatable {
  const FotoItem({required this.id, required this.url});
  final String id;
  final String url;

  factory FotoItem.fromJson(Map<String, dynamic> json) {
    return FotoItem(
      id: json['id'] as String,
      url: json['url'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [id, url];
}

class ChecklistItem extends Equatable {
  const ChecklistItem({
    required this.id,
    required this.checklistId,
    required this.comodoId,
    required this.itemVistoriaId,
    this.estado,
    this.observacao,
    this.fotos = const [],
  });

  final String id;
  final String checklistId;
  final String comodoId;
  final String itemVistoriaId;
  final String? estado;
  final String? observacao;
  final List<FotoItem> fotos;

  bool get preenchido => estado != null && estado!.isNotEmpty;

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    final fotosRaw = json['fotos'] as List? ?? const [];
    return ChecklistItem(
      id: json['id'] as String,
      checklistId: json['checklist_id'] as String? ?? '',
      comodoId: json['comodo_id'] as String? ?? '',
      itemVistoriaId: json['item_vistoria_id'] as String? ?? '',
      estado: json['estado'] as String?,
      observacao: json['observacao'] as String?,
      fotos: fotosRaw
          .whereType<Map>()
          .map((e) => FotoItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  ChecklistItem copyWith({
    String? estado,
    String? observacao,
    List<FotoItem>? fotos,
  }) {
    return ChecklistItem(
      id: id,
      checklistId: checklistId,
      comodoId: comodoId,
      itemVistoriaId: itemVistoriaId,
      estado: estado ?? this.estado,
      observacao: observacao ?? this.observacao,
      fotos: fotos ?? this.fotos,
    );
  }

  @override
  List<Object?> get props => [id, estado, observacao, fotos];
}

class AceiteChecklist extends Equatable {
  const AceiteChecklist({
    required this.id,
    required this.status,
    this.motivoRejeicao,
  });

  final String id;
  final String status;
  final String? motivoRejeicao;

  factory AceiteChecklist.fromJson(Map<String, dynamic> json) {
    return AceiteChecklist(
      id: json['id'] as String,
      status: json['status'] as String? ?? '',
      motivoRejeicao: json['motivo_rejeicao'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, status];
}

class Checklist extends Equatable {
  const Checklist({
    required this.id,
    required this.contratoId,
    required this.vistoriadorId,
    required this.tipo,
    required this.status,
    this.dataVistoria,
    this.createdAt,
    this.itens = const [],
    this.comodos = const [],
    this.aceite,
  });

  final String id;
  final String contratoId;
  final String vistoriadorId;
  final String tipo;
  final String status;
  final DateTime? dataVistoria;
  final DateTime? createdAt;
  final List<ChecklistItem> itens;
  final List<Comodo> comodos;
  final AceiteChecklist? aceite;

  bool get podeEditar => status == 'em_preenchimento';
  bool get pendente => status == 'em_preenchimento';
  bool get aguardandoAceite => status == 'pendente_aceite';
  bool get aceito => status == 'aceito';
  bool get rejeitado => status == 'rejeitado';
  bool get isEncerramento => tipo == 'encerramento';

  int get itensPreenchidos => itens.where((i) => i.preenchido).length;

  factory Checklist.fromJson(Map<String, dynamic> json) {
    final itensRaw = json['itens'] as List? ?? const [];
    final comodosRaw = json['comodos'] as List? ?? const [];
    return Checklist(
      id: json['id'] as String,
      contratoId: json['contrato_id'] as String? ?? '',
      vistoriadorId: json['vistoriador_id'] as String? ?? '',
      tipo: json['tipo'] as String? ?? '',
      status: json['status'] as String? ?? '',
      dataVistoria: DateTime.tryParse(json['data_vistoria'] as String? ?? ''),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      itens: itensRaw
          .whereType<Map>()
          .map((e) => ChecklistItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      comodos: comodosRaw
          .whereType<Map>()
          .map((e) => Comodo.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      aceite: json['aceite'] is Map
          ? AceiteChecklist.fromJson(Map<String, dynamic>.from(json['aceite'] as Map))
          : null,
    );
  }


  @override
  List<Object?> get props => [id, status, itens];
}

class Contrato extends Equatable {
  const Contrato({
    required this.id,
    required this.imovelId,
    required this.locatarioId,
    required this.status,
    this.dataInicio,
    this.dataFim,
    this.valorMensal,
  });

  final String id;
  final String imovelId;
  final String locatarioId;
  final String status;
  final DateTime? dataInicio;
  final DateTime? dataFim;
  final double? valorMensal;

  factory Contrato.fromJson(Map<String, dynamic> json) {
    return Contrato(
      id: json['id'] as String,
      imovelId: json['imovel_id'] as String? ?? '',
      locatarioId: json['locatario_id'] as String? ?? '',
      status: json['status'] as String? ?? '',
      dataInicio: DateTime.tryParse(json['data_inicio'] as String? ?? ''),
      dataFim: DateTime.tryParse(json['data_fim'] as String? ?? ''),
      valorMensal: (json['valor_mensal'] as num?)?.toDouble(),
    );
  }

  @override
  List<Object?> get props => [id];
}

class Agendamento extends Equatable {
  const Agendamento({
    required this.id,
    required this.contratoId,
    required this.tipo,
    this.dataAgendada,
    this.observacao,
  });

  final String id;
  final String contratoId;
  final String tipo;
  final DateTime? dataAgendada;
  final String? observacao;

  factory Agendamento.fromJson(Map<String, dynamic> json) {
    return Agendamento(
      id: json['id'] as String,
      contratoId: json['contrato_id'] as String? ?? '',
      tipo: json['tipo'] as String? ?? '',
      dataAgendada: DateTime.tryParse(json['data_agendada'] as String? ?? ''),
      observacao: json['observacao'] as String?,
    );
  }

  @override
  List<Object?> get props => [id];
}

class AgendaItem extends Equatable {
  const AgendaItem({
    required this.checklist,
    required this.contrato,
    this.imovel,
    this.agendamento,
  });

  final Checklist checklist;
  final Contrato contrato;
  final Imovel? imovel;
  final Agendamento? agendamento;

  @override
  List<Object?> get props => [checklist.id];
}
