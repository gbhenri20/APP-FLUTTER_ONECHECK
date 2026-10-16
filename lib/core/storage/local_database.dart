
import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

/// Persistência local (rascunhos, fila de sync e histórico de operações).
class LocalDatabase {
  LocalDatabase._();

  static const draftsBox = 'oc_drafts';
  static const syncQueueBox = 'oc_sync_queue';
  static const opsLogBox = 'oc_ops_log';
  static const prefsBox = 'oc_prefs';

  static Future<void> init({String? testPath}) async {
    if (testPath != null) {
      Hive.init(testPath);
    } else {
      await Hive.initFlutter();
    }
    await Future.wait([
      Hive.openBox<String>(draftsBox),
      Hive.openBox<String>(syncQueueBox),
      Hive.openBox<String>(opsLogBox),
      Hive.openBox(prefsBox),
    ]);
  }

  Box<String> get drafts => Hive.box<String>(draftsBox);
  Box<String> get syncQueue => Hive.box<String>(syncQueueBox);
  Box<String> get opsLog => Hive.box<String>(opsLogBox);
  Box get prefs => Hive.box(prefsBox);

  Future<void> saveDraft(String key, Map<String, dynamic> data) async {
    await drafts.put(key, jsonEncode(data));
  }

  Map<String, dynamic>? readDraft(String key) {
    final raw = drafts.get(key);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> deleteDraft(String key) => drafts.delete(key);

  Future<void> enqueueSync(Map<String, dynamic> op) async {
    final id = op['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString();
    op['id'] = id;
    op['enqueuedAt'] = DateTime.now().toIso8601String();
    await syncQueue.put(id, jsonEncode(op));
  }

  List<Map<String, dynamic>> pendingSync() {
    return syncQueue.values
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList()
      ..sort((a, b) => (a['enqueuedAt'] as String).compareTo(b['enqueuedAt'] as String));
  }

  Future<void> removeSync(String id) => syncQueue.delete(id);

  Future<void> appendOpLog(Map<String, dynamic> entry) async {
    final id = DateTime.now().toUtc().millisecondsSinceEpoch.toString();
    entry['id'] = id;
    entry['at'] = entry['at'] ?? DateTime.now().toIso8601String();
    await opsLog.put(id, jsonEncode(entry));
    // Mantém no máximo 500 registros
    if (opsLog.length > 500) {
      final keys = opsLog.keys.cast<String>().toList()..sort();
      for (final k in keys.take(opsLog.length - 500)) {
        await opsLog.delete(k);
      }
    }
  }

  List<Map<String, dynamic>> readOpLogs() {
    return opsLog.values
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList()
      ..sort((a, b) => (b['at'] as String).compareTo(a['at'] as String));
  }

  Future<void> clearOpLogs() => opsLog.clear();
}

final localDatabase = LocalDatabase._();
