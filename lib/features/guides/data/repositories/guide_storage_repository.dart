import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Repositorio encargado de gestionar la persistencia local offline de los pasos y fotos
/// de la guía de seguridad vial.
class GuideStorageRepository {
  static const String _prefixSteps = 'guide_steps_';
  static const String _prefixPhotos = 'guide_photos_';

  /// Carga la lista de booleanos para un protocolo específico
  Future<List<bool>> loadCompletedSteps(String protocolId, int totalSteps) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList('$_prefixSteps$protocolId') ??
          prefs.getStringList('pasos_$protocolId'); // Retrocompatibilidad

      if (saved == null || saved.length != totalSteps) {
        return List.filled(totalSteps, false);
      }
      return saved.map((e) => e == 'true').toList();
    } catch (_) {
      return List.filled(totalSteps, false);
    }
  }

  /// Guarda el estado de los pasos completados
  Future<void> saveCompletedSteps(String protocolId, List<bool> steps) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stringList = steps.map((e) => e.toString()).toList();
      await prefs.setStringList('$_prefixSteps$protocolId', stringList);
      await prefs.setStringList('pasos_$protocolId', stringList); // Retrocompatibilidad
    } catch (_) {}
  }

  /// Carga las rutas de archivos de fotos guardadas
  Future<List<File>> loadEvidencePhotos(String protocolId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPaths = prefs.getStringList('$_prefixPhotos$protocolId') ??
          prefs.getStringList('fotos_$protocolId'); // Retrocompatibilidad

      if (savedPaths == null) return [];

      final existingFiles = <File>[];
      for (final p in savedPaths) {
        final f = File(p);
        if (await f.exists()) {
          existingFiles.add(f);
        }
      }
      return existingFiles;
    } catch (_) {
      return [];
    }
  }

  /// Guarda una nueva foto en el directorio de documentos de la app y persiste la ruta
  Future<File?> saveEvidencePhoto(String protocolId, XFile pickedFile) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'evidence_${protocolId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = await File(pickedFile.path).copy('${appDir.path}/$fileName');

      final current = await loadEvidencePhotos(protocolId);
      current.add(savedImage);

      final prefs = await SharedPreferences.getInstance();
      final paths = current.map((f) => f.path).toList();
      await prefs.setStringList('$_prefixPhotos$protocolId', paths);
      await prefs.setStringList('fotos_$protocolId', paths);

      return savedImage;
    } catch (_) {
      return null;
    }
  }

  /// Elimina una foto específica del disco y del registro de SharedPreferences
  Future<void> deleteEvidencePhoto(String protocolId, List<File> currentPhotos, int index) async {
    try {
      if (index >= 0 && index < currentPhotos.length) {
        final fileToDelete = currentPhotos[index];
        if (await fileToDelete.exists()) {
          await fileToDelete.delete();
        }
        currentPhotos.removeAt(index);

        final prefs = await SharedPreferences.getInstance();
        final paths = currentPhotos.map((f) => f.path).toList();
        await prefs.setStringList('$_prefixPhotos$protocolId', paths);
        await prefs.setStringList('fotos_$protocolId', paths);
      }
    } catch (_) {}
  }
}
