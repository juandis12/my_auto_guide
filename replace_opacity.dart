// replace_opacity.dart
import 'dart:io';
import 'dart:convert';

final RegExp opacityRegex = RegExp(r'(Colors\.\w+|Color\([^)]*\))\.withOpacity\(([^)]+)\)');

void main() async {
  final libDir = Directory('lib');
  await for (final entity in libDir.list(recursive: true, followLinks: false)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final original = await entity.readAsString();
      final updated = original.replaceAllMapped(opacityRegex, (match) {
        final color = match[1];
        final opacity = match[2];
        return '${color}.withValues(alpha: $opacity)';
      });
      if (original != updated) {
        await entity.writeAsString(updated);
        stdout.writeln('Updated ${entity.path}');
      }
    }
  }
}
