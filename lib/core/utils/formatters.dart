
import 'package:intl/intl.dart';

final _date = DateFormat('dd/MM/yyyy', 'pt_BR');
final _dateTime = DateFormat('dd/MM/yyyy HH:mm', 'pt_BR');

String formatDate(DateTime? value) {
  if (value == null) return '—';
  return _date.format(value.toLocal());
}

String formatDateTime(DateTime? value) {
  if (value == null) return '—';
  return _dateTime.format(value.toLocal());
}

DateTime? parseApiDate(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  try {
    return DateTime.parse(raw);
  } catch (_) {
    return null;
  }
}

String labelChecklistStatus(String status) {
  switch (status) {
    case 'em_preenchimento':
      return 'Em preenchimento';
    case 'pendente_aceite':
      return 'Aguardando aprovação';
    case 'aceito':
      return 'Aceita';
    case 'rejeitado':
      return 'Rejeitada';
    case 'finalizado':
      return 'Finalizada';
    default:
      return status;
  }
}

String labelEstadoItem(String? estado) {
  switch (estado) {
    case 'otimo':
      return 'Ótimo';
    case 'bom':
      return 'Bom';
    case 'regular':
      return 'Regular';
    case 'ruim':
      return 'Ruim';
    default:
      return 'Pendente';
  }
}

String labelTipoVistoria(String tipo) {
  switch (tipo) {
    case 'inicial':
      return 'Entrada';
    case 'encerramento':
      return 'Saída';
    default:
      return tipo;
  }
}

String labelRole(String role) {
  switch (role) {
    case 'admin':
      return 'Administrador';
    case 'gestor':
      return 'Gestor';
    case 'vistoriador':
      return 'Vistoriador';
    case 'locatario':
      return 'Locatário';
    default:
      return role;
  }
}
