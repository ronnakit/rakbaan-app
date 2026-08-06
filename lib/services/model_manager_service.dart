import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Resolves the on-disk path of the quantized `.gguf` model, downloading it
/// on first launch if it isn't there yet.
///
/// Why download instead of bundling the file as a Flutter asset: a q4_k_m
/// quantized 2B model is roughly 1.5-1.7 GB. Bundling that inside the app
/// package would blow past Play Store's base APK/AAB limits and Apple's
/// cellular-download cap, and would force a full app-store review cycle
/// every time the model itself is updated. Downloading it once into the
/// app's private documents directory keeps the app binary small and lets you
/// ship model updates independently of app releases.
class ModelManagerService {
  ModelManagerService();

  static const String modelFileName = 'malii-home-repair-q4_k_m.gguf';

  /// TODO: point this at your own storage (S3, Firebase Storage, your own
  /// server, or a direct Hugging Face "resolve/main/...gguf" link). It must
  /// be a plain HTTPS URL that returns the raw .gguf bytes.
  static const String modelDownloadUrl =
      'https://example.com/replace-with-your-model-url/malii-home-repair-q4_k_m.gguf';

  Future<Directory> _modelDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/models');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<File> _modelFile() async {
    final dir = await _modelDir();
    return File('${dir.path}/$modelFileName');
  }

  Future<bool> isModelReady() async {
    final file = await _modelFile();
    if (!await file.exists()) return false;
    return await file.length() > 0;
  }

  /// Returns the local file path to the model, downloading it first if
  /// needed. [onProgress] receives a value in `[0.0, 1.0]`.
  Future<String> ensureModelPath({
    required void Function(double progress) onProgress,
  }) async {
    final file = await _modelFile();
    if (await isModelReady()) {
      onProgress(1.0);
      return file.path;
    }
    await _download(file, onProgress);
    return file.path;
  }

  Future<void> _download(
    File destination,
    void Function(double progress) onProgress,
  ) async {
    final partialFile = File('${destination.path}.part');
    final request = http.Request('GET', Uri.parse(modelDownloadUrl));
    final response = await request.send();

    if (response.statusCode != 200) {
      throw Exception('ดาวน์โหลดโมเดลไม่สำเร็จ (HTTP ${response.statusCode})');
    }

    final totalBytes = response.contentLength ?? 0;
    var receivedBytes = 0;
    final sink = partialFile.openWrite();

    try {
      await for (final chunk in response.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0) {
          onProgress(receivedBytes / totalBytes);
        }
      }
      await sink.flush();
      await sink.close();
      await partialFile.rename(destination.path);
    } catch (e) {
      await sink.close();
      if (await partialFile.exists()) {
        await partialFile.delete();
      }
      rethrow;
    }
  }
}
