
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ImageCompressor {
  const ImageCompressor({
    this.maxWidth = 1600,
    this.quality = 75,
  });

  final int maxWidth;
  final int quality;

  /// Comprime imagem preservando qualidade suficiente para vistoria.
  /// Em Web, retorna os bytes originais (compressão nativa indisponível).
  Future<CompressedImage> compress({
    required String path,
    Uint8List? bytes,
  }) async {
    if (kIsWeb) {
      final data = bytes ?? await File(path).readAsBytes();
      return CompressedImage(
        bytes: data,
        filename: p.basename(path),
        mimeType: 'image/jpeg',
      );
    }

    final dir = await getTemporaryDirectory();
    final target = p.join(
      dir.path,
      'oc_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    final result = await FlutterImageCompress.compressAndGetFile(
      path,
      target,
      quality: quality,
      minWidth: maxWidth,
      minHeight: maxWidth,
      format: CompressFormat.jpeg,
    );
    final outPath = result?.path ?? path;
    final outBytes = await File(outPath).readAsBytes();
    return CompressedImage(
      bytes: outBytes,
      filename: p.basename(outPath),
      mimeType: 'image/jpeg',
      localPath: outPath,
    );
  }
}

class CompressedImage {
  const CompressedImage({
    required this.bytes,
    required this.filename,
    required this.mimeType,
    this.localPath,
  });

  final Uint8List bytes;
  final String filename;
  final String mimeType;
  final String? localPath;
}
