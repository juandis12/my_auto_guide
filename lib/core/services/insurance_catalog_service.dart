// =============================================================================
// insurance_catalog_service.dart — CATÁLOGO OFICIAL DE ASEGURADORAS (COLOMBIA)
// =============================================================================
//
// Provee la lista exhaustiva y verificada de aseguradoras autorizadas en
// Colombia que ofrecen cobertura todo riesgo para automóviles y motocicletas,
// con sus canales directos de WhatsApp, portal de siniestros y líneas de auxilio.
//
// =============================================================================

import '../../features/vehicles/domain/models/insurance_company_model.dart';

class InsuranceCatalogService {
  static const String noneId = 'none';

  static const InsuranceCompany noneCompany = InsuranceCompany(
    id: noneId,
    name: 'No tengo aseguradora todo riesgo',
    emergencyPhone: '123',
    tollFreePhone: null,
    whatsappNumber: null,
    webClaimsUrl: '',
    supportsCars: true,
    supportsMotorcycles: true,
    defaultReportMessage: '',
  );

  /// Catálogo maestro de aseguradoras todo riesgo en Colombia
  static const List<InsuranceCompany> allInsurers = [
    InsuranceCompany(
      id: 'sura',
      name: 'Seguros SURA',
      emergencyPhone: '#888',
      tollFreePhone: '018000518888',
      whatsappNumber: '573152757888',
      webClaimsUrl: 'https://www.sura.co/asistencia-autos',
      supportsCars: true,
      supportsMotorcycles: true,
      defaultReportMessage:
          'Hola SURA, necesito reportar un siniestro y solicitar asistencia para mi vehículo.',
    ),
    InsuranceCompany(
      id: 'bolivar',
      name: 'Seguros Bolívar',
      emergencyPhone: '#322',
      tollFreePhone: '018000123322',
      whatsappNumber: '573223322322',
      webClaimsUrl: 'https://www.segurosbolivar.com/asistencias-siniestros',
      supportsCars: true,
      supportsMotorcycles: true,
      defaultReportMessage:
          'Hola OlivIA / Seguros Bolívar, requiero asistencia inmediata por un siniestro vial.',
    ),
    InsuranceCompany(
      id: 'axa_colpatria',
      name: 'AXA Colpatria',
      emergencyPhone: '#247',
      tollFreePhone: '018000512620',
      whatsappNumber: '573153820629',
      webClaimsUrl: 'https://www.axacolpatria.co/portal/Atencion-al-Cliente',
      supportsCars: true,
      supportsMotorcycles: true,
      defaultReportMessage:
          'Hola AXA Colpatria, deseo reportar un accidente y solicitar asistencia para mi póliza todo riesgo.',
    ),
    InsuranceCompany(
      id: 'allianz',
      name: 'Allianz Colombia',
      emergencyPhone: '#265',
      tollFreePhone: '018000513500',
      whatsappNumber: null, // Centralizado vía #265 y portal web oficial
      webClaimsUrl: 'https://www.allianz.co/siniestros/autos.html',
      supportsCars: true,
      supportsMotorcycles: true,
      defaultReportMessage:
          'Hola Allianz, necesito reportar un siniestro de autos.',
    ),
    InsuranceCompany(
      id: 'estado',
      name: 'Seguros del Estado',
      emergencyPhone: '#388',
      tollFreePhone: '018000123010',
      whatsappNumber: null,
      webClaimsUrl: 'https://www.segurosdelestado.com/canales-atencion',
      supportsCars: true,
      supportsMotorcycles: true,
      defaultReportMessage:
          'Hola Seguros del Estado, necesito reportar un siniestro de mi vehículo.',
    ),
    InsuranceCompany(
      id: 'mapfre',
      name: 'MAPFRE Seguros',
      emergencyPhone: '#324',
      tollFreePhone: '018000919938',
      whatsappNumber: '573132646274',
      webClaimsUrl: 'https://www.mapfre.com.co/siniestros-autos',
      supportsCars: true,
      supportsMotorcycles: true,
      defaultReportMessage:
          'Hola MAPFRE, requiero asistencia y reporte de siniestro con mi vehículo asegurado.',
    ),
    InsuranceCompany(
      id: 'la_equidad',
      name: 'La Equidad Seguros',
      emergencyPhone: '#324',
      tollFreePhone: '018000919538',
      whatsappNumber: null,
      webClaimsUrl: 'https://www.laequidadseguros.coop/canales-de-atencion',
      supportsCars: true,
      supportsMotorcycles: true,
      defaultReportMessage:
          'Hola La Equidad, solicito asistencia para mi póliza todo riesgo.',
    ),
    InsuranceCompany(
      id: 'hdi',
      name: 'HDI Seguros Colombia',
      emergencyPhone: '#204',
      tollFreePhone: '018000115570',
      whatsappNumber: '573176587425',
      webClaimsUrl: 'https://www.hdi.com.co/atencion-siniestros',
      supportsCars: true,
      supportsMotorcycles: false,
      defaultReportMessage:
          'Hola HDI Seguros, requiero reportar un siniestro y asistencia de grúa/taller.',
    ),
    InsuranceCompany(
      id: 'previsora',
      name: 'Previsora Seguros',
      emergencyPhone: '#345',
      tollFreePhone: '018000910554',
      whatsappNumber: null,
      webClaimsUrl: 'https://www.previsora.gov.co/canales-de-atencion',
      supportsCars: true,
      supportsMotorcycles: false,
      defaultReportMessage:
          'Hola Previsora Seguros, solicito asistencia por siniestro vial.',
    ),
    InsuranceCompany(
      id: 'liberty',
      name: 'Liberty Seguros',
      emergencyPhone: '#224',
      tollFreePhone: '018000113390',
      whatsappNumber: null,
      webClaimsUrl: 'https://www.libertyseguros.co/asistencia-vehicular',
      supportsCars: true,
      supportsMotorcycles: false,
      defaultReportMessage:
          'Hola Liberty Seguros, necesito reporte de siniestro para mi vehículo.',
    ),
    InsuranceCompany(
      id: 'mundial',
      name: 'Seguros Mundial',
      emergencyPhone: '#455',
      tollFreePhone: '018000111935',
      whatsappNumber: '573164741484',
      webClaimsUrl: 'https://www.mundialseguros.com.co/siniestros',
      supportsCars: true,
      supportsMotorcycles: true,
      defaultReportMessage:
          'Hola Seguros Mundial, necesito reportar un siniestro y asistencia.',
    ),
    InsuranceCompany(
      id: 'sbs',
      name: 'SBS Seguros',
      emergencyPhone: '#360',
      tollFreePhone: '018000517555',
      whatsappNumber: null,
      webClaimsUrl: 'https://www.sbsseguros.co/atencion-cliente',
      supportsCars: true,
      supportsMotorcycles: false,
      defaultReportMessage:
          'Hola SBS Seguros, necesito reportar un accidente vial.',
    ),
    InsuranceCompany(
      id: 'zurich',
      name: 'Zurich Colombia',
      emergencyPhone: '#795',
      tollFreePhone: '018000518795',
      whatsappNumber: null,
      webClaimsUrl: 'https://www.zurich.com.co/asistencia-autos',
      supportsCars: true,
      supportsMotorcycles: false,
      defaultReportMessage:
          'Hola Zurich Seguros, solicito asistencia de emergencia para mi auto.',
    ),
  ];

  /// Obtiene la lista filtrada de aseguradoras según el tipo de vehículo.
  /// Incluye como primera opción siempre la opción "No tengo aseguradora".
  static List<InsuranceCompany> getInsurersForSelection({
    required bool isMoto,
  }) {
    final filtered = allInsurers.where((c) {
      return isMoto ? c.supportsMotorcycles : c.supportsCars;
    }).toList();

    return [noneCompany, ...filtered];
  }

  /// Busca una aseguradora por su identificador.
  static InsuranceCompany? findById(String? id) {
    if (id == null || id.isEmpty || id == noneId) {
      return null;
    }
    for (final company in allInsurers) {
      if (company.id == id) return company;
    }
    return null;
  }
}
