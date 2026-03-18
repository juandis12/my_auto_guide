import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class NominatimPlace {
  final String displayName;
  final double lat;
  final double lon;

  NominatimPlace({
    required this.displayName,
    required this.lat,
    required this.lon,
  });

  factory NominatimPlace.fromJson(Map<String, dynamic> json) {
    return NominatimPlace(
      displayName: json['display_name'] ?? 'Destino',
      lat: double.tryParse(json['lat'].toString()) ?? 0.0,
      lon: double.tryParse(json['lon'].toString()) ?? 0.0,
    );
  }
}

class OSRMRoute {
  final List<LatLng> points;
  final double distanceKm;
  final double durationMin;

  OSRMRoute({
    required this.points,
    required this.distanceKm,
    required this.durationMin,
  });
}

class NavigationLogicException implements Exception {
  final String message;
  NavigationLogicException(this.message);
  @override
  String toString() => message;
}

class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  /// Consulta la API de Nominatim para obtener lugares
  Future<List<NominatimPlace>> searchDestination(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}'
        '&format=json&limit=5&addressdetails=1',
      );
      final res = await http.get(url, headers: {
        'User-Agent': 'MyAutoGuide/1.0',
      });

      if (res.statusCode == 200) {
        final data = json.decode(res.body) as List;
        return data.map((e) => NominatimPlace.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        throw NavigationLogicException('El servidor de mapas no respondió (Code: ${res.statusCode})');
      }
    } catch (e) {
      if (e is NavigationLogicException) rethrow;
      throw NavigationLogicException('Error de conexión a internet o al buscar dirección.');
    }
  }

  /// Calcula la ruta desde un OSRM Engine público
  Future<OSRMRoute> calculateRoute(LatLng origin, LatLng destination) async {
    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${origin.longitude},${origin.latitude};'
        '${destination.longitude},${destination.latitude}'
        '?overview=full&geometries=geojson&steps=true',
      );
      final res = await http.get(url);

      if (res.statusCode == 200) {
        final data = json.decode(res.body);

        if (data['routes'] == null || (data['routes'] as List).isEmpty) {
          throw NavigationLogicException('No se encontró una ruta válida hacia este destino.');
        }

        final route = data['routes'][0];
        final coords = route['geometry']['coordinates'] as List;
        final distMeters = (route['distance'] as num).toDouble();
        final durSeconds = (route['duration'] as num).toDouble();

        final points = coords
            .map((c) =>
                LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
            .toList();

        return OSRMRoute(
          points: points,
          distanceKm: distMeters / 1000,
          durationMin: durSeconds / 60,
        );
      } else {
        throw NavigationLogicException('Servidor de rutas no disponible. (${res.statusCode})');
      }
    } catch (e) {
      if (e is NavigationLogicException) rethrow;
      throw NavigationLogicException('Error al trazar ruta: $e');
    }
  }
}
