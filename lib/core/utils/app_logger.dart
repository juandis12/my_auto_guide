import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Registro centralizado de errores.
///
/// [error] es para fallas que no deberían ocurrir: se imprimen en consola y se
/// reportan a Sentry. [warning] es para fallas esperadas y recuperables (modo
/// offline, datos opcionales que no llegaron): sólo dejan rastro en consola y
/// como breadcrumb, para que aparezcan como contexto si luego ocurre un error.
///
/// [context] identifica el origen, por convención `Clase.metodo`.
class AppLogger {
  const AppLogger._();

  static void error(String context, Object error, [StackTrace? stackTrace]) {
    debugPrint('[ERROR] $context: $error');
    if (stackTrace != null) {
      debugPrintStack(stackTrace: stackTrace, label: context);
    }
    Sentry.captureException(
      error,
      stackTrace: stackTrace,
      withScope: (scope) => scope.setTag('origen', context),
    ).ignore();
  }

  static void warning(String context, Object error, [StackTrace? stackTrace]) {
    debugPrint('[WARN] $context: $error');
    Sentry.addBreadcrumb(
      Breadcrumb(
        message: '$context: $error',
        level: SentryLevel.warning,
      ),
    ).ignore();
  }
}
