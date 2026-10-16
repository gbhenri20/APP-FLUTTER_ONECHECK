import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../checklist/domain/checklist_models.dart';

final agendaProvider = FutureProvider.autoDispose<List<AgendaItem>>((ref) async {
  return ref.watch(agendaRepositoryProvider).carregarAgenda(
        ocultarEncerramento: true,
      );
});
