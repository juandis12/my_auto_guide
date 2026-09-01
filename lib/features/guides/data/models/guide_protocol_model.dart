import 'package:flutter/material.dart';

/// Modelo que representa un escenario o protocolo de seguridad vial.
class GuideProtocol {
  final String id;
  final String title;
  final String subtitle;
  final String category;
  final IconData icon;
  final Color accentColor;
  final List<String> steps;
  final String bannerDescription;
  final bool allowsPhotoEvidence;

  const GuideProtocol({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.icon,
    required this.accentColor,
    required this.steps,
    required this.bannerDescription,
    this.allowsPhotoEvidence = true,
  });

  /// Lista predeterminada de protocolos con información estructurada
  static const List<GuideProtocol> defaultProtocols = [
    GuideProtocol(
      id: 'leve',
      title: 'Accidente Leve',
      subtitle: 'Gestión ágil de incidentes menores sin heridos',
      category: 'Emergencia',
      icon: Icons.car_crash_rounded,
      accentColor: Color(0xFF38BDF8), // Electric Cyan
      bannerDescription:
          'Sigue estos pasos para documentar daños, evitar congestión y tramitar con tu aseguradora de forma segura.',
      allowsPhotoEvidence: true,
      steps: [
        'Mantén la calma y verifica que todos los ocupantes estén bien.',
        'Muévete a un lugar seguro para evitar un segundo impacto.',
        'Evalúa los daños materiales y comprueba si hay raspones o lesiones leves.',
        'Intercambia datos completos con el otro conductor (nombre, cédula, placa, teléfono y aseguradora).',
        'Toma fotografías y videos panorámicos de la escena antes de mover los vehículos si es seguro.',
        'Notifica de inmediato a tu compañía aseguradora mediante su línea de asistencia.',
      ],
    ),
    GuideProtocol(
      id: 'grave',
      title: 'Accidente Grave',
      subtitle: 'Protocolo de alta prioridad para emergencias críticas',
      category: 'Crítico',
      icon: Icons.warning_amber_rounded,
      accentColor: Color(0xFFF43F5E), // Apple Rose / Red
      bannerDescription:
          'Prioriza la vida y la integridad física. No muevas heridos a menos que exista riesgo inminente de fuego o explosión.',
      allowsPhotoEvidence: true,
      steps: [
        'Mantén la calma y evalúa tu propia seguridad antes de auxiliar a otros.',
        'Llama de inmediato a la línea única de emergencias (123 o tu número local).',
        'NO muevas a personas heridas a menos que haya peligro inminente de incendio.',
        'Coloca los triángulos de señalización a mínimo 50 metros y activa luces de parqueo.',
        'Registra evidencia fotográfica de la posición de los vehículos y la vía si no hay peligro.',
        'Permanece en el sitio, coopera con las autoridades de tránsito y la policía.',
      ],
    ),
    GuideProtocol(
      id: 'lluvia',
      title: 'Conducción en Lluvia',
      subtitle: 'Técnicas defensivas para asfalto mojado y neblina',
      category: 'Clima',
      icon: Icons.water_drop_rounded,
      accentColor: Color(0xFF06B6D4), // Cyan Aqua
      bannerDescription:
          'El asfalto mojado reduce la adherencia de las llantas y aumenta la distancia de frenado hasta un 50%.',
      allowsPhotoEvidence: false,
      steps: [
        'Reduce la velocidad entre un 20% y 30% respecto al límite permitido.',
        'Aumenta la distancia de seguridad con el vehículo de adelante al doble.',
        'Enciende las luces bajas y exploradoras para maximizar visibilidad sin encandilar.',
        'Evita frenar bruscamente o hacer giros secos para prevenir el aquaplaning.',
        'Si encuentras un tramo inundado donde el agua cubra más de media llanta, no cruces.',
        'Mantén activado el desempañador del parabrisas y las plumillas limpias.',
      ],
    ),
    GuideProtocol(
      id: 'viaje',
      title: 'Preparación Viaje Largo',
      subtitle: 'Checklist previo a ruta intermunicipal o carretera',
      category: 'Prevención',
      icon: Icons.explore_rounded,
      accentColor: Color(0xFFF59E0B), // Apple Amber
      bannerDescription:
          'Garantiza un viaje seguro y sin contratiempos revisando los puntos clave de tu vehículo antes de salir.',
      allowsPhotoEvidence: false,
      steps: [
        'Inspecciona presión de llantas (incluyendo repuesto), nivel de aceite y refrigerante.',
        'Verifica el funcionamiento de todas las luces (altas, bajas, direccionales y freno).',
        'Asegúrate de llevar el kit de carretera completo, botiquín al día y extintor con carga.',
        'Descansa mínimo 7-8 horas la noche anterior al viaje.',
        'Planifica paradas activas de estiramiento y descanso cada 2 horas o 200 km.',
        'Verifica que el SOAT y la Revisión Técnico-Mecánica estén vigentes.',
      ],
    ),
  ];
}
