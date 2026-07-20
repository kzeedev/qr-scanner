import 'dart:async';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:open_file_plus/open_file_plus.dart';
import 'package:path_provider/path_provider.dart';

class ApkDownloadResult {
  final bool success;
  final File? apkFile;
  final String? computedSha1;
  final String? expectedSha1;
  final String? error;

  ApkDownloadResult({
    required this.success,
    this.apkFile,
    this.computedSha1,
    this.expectedSha1,
    this.error,
  });
}

class ApkDownloadService {
  final http.Client _client;

  ApkDownloadService({http.Client? client}) : _client = client ?? http.Client();

  Future<File> downloadApk({
    required String apkUrl,
    required void Function(int receivedBytes, int totalBytes) onProgress,
  }) async {
    final request = http.Request('GET', Uri.parse(apkUrl));
    request.headers['User-Agent'] = 'BulkBarcodeScannerApp';

    final response = await _client.send(request);

    if (response.statusCode != 200) {
      throw Exception('Failed to download APK. Status code: ${response.statusCode}');
    }

    final totalBytes = response.contentLength ?? 0;
    int receivedBytes = 0;

    final tempDir = await getTemporaryDirectory();
    final apkFile = File('${tempDir.path}/update_${DateTime.now().millisecondsSinceEpoch}.apk');
    final sink = apkFile.openWrite();

    final completer = Completer<File>();

    response.stream.listen(
      (chunk) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        onProgress(receivedBytes, totalBytes);
      },
      onDone: () async {
        await sink.close();
        completer.complete(apkFile);
      },
      onError: (e) async {
        await sink.close();
        if (await apkFile.exists()) {
          await apkFile.delete();
        }
        completer.completeError(e);
      },
      cancelOnError: true,
    );

    return completer.future;
  }

  Future<String?> fetchExpectedSha1(String sha1Url) async {
    try {
      final response = await _client.get(
        Uri.parse(sha1Url),
        headers: {'User-Agent': 'BulkBarcodeScannerApp'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final text = response.body.trim();
        final match = RegExp(r'[0-9a-fA-F]{40}').firstMatch(text);
        if (match != null) {
          return match.group(0)!.toLowerCase();
        }
        return text.split(RegExp(r'\s+')).first.toLowerCase();
      }
    } catch (_) {
      // Failed to fetch sha1 URL
    }
    return null;
  }

  Future<String> computeFileSha1(File file) async {
    final stream = file.openRead();
    final digest = await sha1.bind(stream).first;
    return digest.toString().toLowerCase();
  }

  Future<OpenResult> installApk(File apkFile) async {
    return await OpenFile.open(apkFile.path);
  }
}
