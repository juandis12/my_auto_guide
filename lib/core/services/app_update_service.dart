import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import 'package:open_filex/open_filex.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppUpdateInfo {
  final int versionCode;
  final String versionName;
  final String zipUrl;
  final String releaseNotes;
  final bool isMandatory;
  final int? fileSizeBytes;

  const AppUpdateInfo({
    required this.versionCode,
    required this.versionName,
    required this.zipUrl,
    required this.releaseNotes,
    required this.isMandatory,
    this.fileSizeBytes,
  });

  factory AppUpdateInfo.fromMap(Map<String, dynamic> map) {
    return AppUpdateInfo(
      versionCode: (map['version_code'] as num?)?.toInt() ?? 0,
      versionName: (map['version_name'] as String?) ?? '1.0.0',
      zipUrl: (map['zip_url'] as String?) ?? '',
      releaseNotes: (map['release_notes'] as String?) ?? 'Mejoras de rendimiento y estabilidad.',
      isMandatory: (map['is_mandatory'] as bool?) ?? true,
      fileSizeBytes: (map['file_size_bytes'] as num?)?.toInt(),
    );
  }
}

class AppUpdateService {
  static final AppUpdateService _instance = AppUpdateService._internal();
  factory AppUpdateService() => _instance;
  AppUpdateService._internal();

  /// Consulta en Supabase si existe una versión superior a la instalada.
  Future<AppUpdateInfo?> checkForUpdate() async {
    // Solo Android soporta actualización OTA mediante APK
    if (!Platform.isAndroid) return null;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;

      final client = Supabase.instance.client;
      final response = await client
          .from('app_versions')
          .select()
          .order('version_code', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;

      final updateInfo = AppUpdateInfo.fromMap(response);

      if (updateInfo.versionCode > currentBuildNumber && updateInfo.zipUrl.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('[OTA Update] Nueva versión detectada: ${updateInfo.versionName} (${updateInfo.versionCode}) vs Actual: ${packageInfo.version} ($currentBuildNumber)');
        }
        return updateInfo;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[OTA Update] Error consultando actualización: $e');
      }
    }
    return null;
  }

  /// Descarga el archivo ZIP desde Supabase Storage y descomprime el APK en segundo plano.
  Future<String?> downloadAndExtractApk({
    required String zipUrl,
    required void Function(double progress, String status) onProgress,
  }) async {
    try {
      onProgress(0.05, 'Conectando con el servidor de descargas...');

      final client = http.Client();
      final request = http.Request('GET', Uri.parse(zipUrl))
        ..followRedirects = true
        ..maxRedirects = 10
        ..headers.addAll({
          'User-Agent': 'MyAutoGuide-OTA/1.0',
          'Accept': '*/*',
        });
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw HttpException('Error del servidor: HTTP ${response.statusCode}');
      }

      final contentLength = response.contentLength ?? 0;
      final tempDir = await getTemporaryDirectory();
      final isDirectApk = zipUrl.toLowerCase().contains('.apk');

      final downloadTargetFilePath = isDirectApk 
          ? p.join(tempDir.path, 'app_update_ready.apk')
          : p.join(tempDir.path, 'update_release.zip');

      final targetFile = File(downloadTargetFilePath);
      if (await targetFile.exists()) await targetFile.delete();

      final sink = targetFile.openWrite();
      int downloadedBytes = 0;

      await for (final chunk in response.stream) {
        sink.add(chunk);
        downloadedBytes += chunk.length;

        if (contentLength > 0) {
          final downloadRatio = (downloadedBytes / contentLength).clamp(0.0, 1.0);
          final progress = isDirectApk 
              ? (0.05 + (downloadRatio * 0.90))
              : (0.05 + (downloadRatio * 0.70));
          final mbDownloaded = (downloadedBytes / (1024 * 1024)).toStringAsFixed(1);
          final mbTotal = (contentLength / (1024 * 1024)).toStringAsFixed(1);
          onProgress(progress, 'Descargando actualización ($mbDownloaded / $mbTotal MB)...');
        } else {
          onProgress(0.50, 'Descargando actualización...');
        }
      }

      await sink.flush();
      await sink.close();
      client.close();

      if (isDirectApk) {
        onProgress(1.0, '¡Descarga completada con éxito!');
        return downloadTargetFilePath;
      }

      onProgress(0.80, 'Descomprimiendo paquete de actualización...');

      // Ejecutar descompresión pesada en Isolate para no congelar la UI a 60 FPS
      final extractedApkPath = await Isolate.run(() async {
        final bytes = await targetFile.readAsBytes();
        final archive = ZipDecoder().decodeBytes(bytes);

        for (final file in archive) {
          if (file.isFile && file.name.toLowerCase().endsWith('.apk')) {
            final apkOutPath = p.join(tempDir.path, 'app_update_ready.apk');
            final apkFile = File(apkOutPath);
            if (await apkFile.exists()) await apkFile.delete();
            await apkFile.writeAsBytes(file.content as List<int>, flush: true);
            return apkOutPath;
          }
        }
        return null;
      });

      // Limpiar archivo ZIP temporal
      try {
        if (await targetFile.exists()) await targetFile.delete();
      } catch (_) {}

      if (extractedApkPath == null) {
        throw Exception('El archivo descargado no contiene un archivo .apk válido.');
      }

      onProgress(1.0, '¡Actualización lista para instalar!');
      return extractedApkPath;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[OTA Update] Error en descarga/descompresión: $e');
      }
      onProgress(0.0, 'Error: $e');
      return null;
    }
  }

  /// Abre el instalador nativo de Android mediante FileProvider.
  Future<bool> installApk(String apkPath) async {
    try {
      final file = File(apkPath);
      if (!await file.exists()) {
        if (kDebugMode) debugPrint('[OTA Update] Archivo APK no encontrado en: $apkPath');
        return false;
      }

      final result = await OpenFilex.open(
        apkPath,
        type: 'application/vnd.android.package-archive',
      );

      if (kDebugMode) {
        debugPrint('[OTA Update] Resultado de instalación: ${result.type} - ${result.message}');
      }
      return result.type == ResultType.done;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[OTA Update] Error al invocar instalador de APK: $e');
      }
      return false;
    }
  }
}
