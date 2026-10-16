import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../domain/checklist_models.dart';

final checklistDetailProvider =
    FutureProvider.autoDispose.family<Checklist, String>((ref, id) async {
  return ref.watch(checklistRepositoryProvider).getChecklist(id);
});

final itensCatalogoProvider =
    FutureProvider.autoDispose<List<ItemVistoriaCatalogo>>((ref) async {
  return ref.watch(checklistRepositoryProvider).listItensCatalogo();
});
