// =============================================================================
// insurance_company_model.dart — MODELO DE ASEGURADORA TODO RIESGO (COLOMBIA)
// =============================================================================

/// Representa una compañía aseguradora autorizada en Colombia con sus canales
/// de atención inmediata y reporte de siniestros.
class InsuranceCompany {
  /// Identificador único (ej. 'sura', 'bolivar', 'allianz')
  final String id;

  /// Nombre comercial visible
  final String name;

  /// Línea de asistencia telefónica corta o nacional (ej. '#888', '#322')
  final String emergencyPhone;

  /// Teléfono 018000 o fijo nacional
  final String? tollFreePhone;

  /// Número de WhatsApp en formato internacional E.164 (sin '+', ej: '573152757888')
  final String? whatsappNumber;

  /// URL del portal web oficial para radicar o reportar siniestros / asistencia
  final String webClaimsUrl;

  /// Aplica para póliza todo riesgo de automóviles
  final bool supportsCars;

  /// Aplica para póliza todo riesgo de motocicletas
  final bool supportsMotorcycles;

  /// Mensaje por defecto para iniciar el reporte en WhatsApp
  final String defaultReportMessage;

  const InsuranceCompany({
    required this.id,
    required this.name,
    required this.emergencyPhone,
    this.tollFreePhone,
    this.whatsappNumber,
    required this.webClaimsUrl,
    required this.supportsCars,
    required this.supportsMotorcycles,
    this.defaultReportMessage =
        'Hola, necesito asistencia y reportar un siniestro con mi póliza todo riesgo.',
  });

  /// URL lista para abrir WhatsApp con mensaje codificado
  String? get whatsappUrl {
    if (whatsappNumber == null || whatsappNumber!.trim().isEmpty) return null;
    final encodedMsg = Uri.encodeComponent(defaultReportMessage);
    return 'https://wa.me/${whatsappNumber!.trim()}?text=$encodedMsg';
  }

  /// URL telefónica para marcar directamente desde el dispositivo
  String get callUrl {
    // Si inicia con '#', en URLs telefónicas suele requerir codificación o el número directo
    final cleaned = emergencyPhone.replaceAll(' ', '');
    return 'tel:$cleaned';
  }
}
