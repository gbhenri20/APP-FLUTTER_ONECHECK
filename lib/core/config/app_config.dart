import 'dart:convert';

import 'package:flutter/services.dart';

/// Configuração centralizada por ambiente (dev / test / production).
class AppConfig {
  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.apiPrefix,
    required this.connectTimeoutMs,
    required this.receiveTimeoutMs,
    required this.enableOfflineSync,
    required this.imageMaxWidth,
    required this.imageQuality,
  });

  final String environment;
  final String apiBaseUrl;
  final String apiPrefix;
  final int connectTimeoutMs;
  final int receiveTimeoutMs;
  final bool enableOfflineSync;
  final int imageMaxWidth;
  final int imageQuality;

  String get apiRoot =>
      '${apiBaseUrl.replaceAll(RegExp(r'/$'), '')}$apiPrefix';

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      environment: json['environment'] as String? ?? 'development',
      apiBaseUrl: json['apiBaseUrl'] as String? ?? 'http://127.0.0.1:8765',
      apiPrefix: json['apiPrefix'] as String? ?? '/api/v1',
      connectTimeoutMs: json['connectTimeoutMs'] as int? ?? 20000,
      receiveTimeoutMs: json['receiveTimeoutMs'] as int? ?? 30000,
      enableOfflineSync: json['enableOfflineSync'] as bool? ?? true,
      imageMaxWidth: json['imageMaxWidth'] as int? ?? 1600,
      imageQuality: json['imageQuality'] as int? ?? 75,
    );
  }

  static Future<AppConfig> load({String assetPath = 'assets/env/app_config.json'}) async {
    final raw = await rootBundle.loadString(assetPath);
    return AppConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  /// Permite override em testes sem asset bundle.
  static AppConfig forTests({String baseUrl = 'http://127.0.0.1:8765'}) {
    return AppConfig(
      environment: 'test',
      apiBaseUrl: baseUrl,
      apiPrefix: '/api/v1',
      connectTimeoutMs: 5000,
      receiveTimeoutMs: 5000,
      enableOfflineSync: true,
      imageMaxWidth: 800,
      imageQuality: 70,
    );
  }
}
