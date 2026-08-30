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

class NavigationStep {
  final String instruction;
  final double distanceMeters;
  final double durationSeconds;
  final String maneuverType;
  final String? modifier;
  final LatLng location;

  NavigationStep({
    required this.instruction,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.maneuverType,
    this.modifier,
    required this.location,
  });
}

class OSRMRoute {
  final List<LatLng> points;
  final double distanceKm;
  final double durationMin;
  final List<NavigationStep> steps;

  OSRMRoute({
    required this.points,
    required this.distanceKm,
    required this.durationMin,
    this.steps = const [],
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

  /// Consulta la API de Nominatim para obtener lugares por texto
  Future<List<NominatimPlace>> searchDestination(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}'
        '&format=json&limit=6&addressdetails=1',
      );
      final res = await http.get(url, headers: {
        'User-Agent': 'MyAutoGuide-App/2.0 (my.auto.guide.app@gmail.com)',
      }).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final data = json.decode(res.body) as List;
        if (data.isNotEmpty) {
          return data.map((e) => NominatimPlace.fromJson(e as Map<String, dynamic>)).toList();
        }
      }
      
      // Fallback a Photon (Komoot OSM Geocoder) si Nominatim da 429 o está vacío
      return await _searchWithPhotonFallback(query);
    } catch (_) {
      return await _searchWithPhotonFallback(query);
    }
  }

  Future<List<NominatimPlace>> _searchWithPhotonFallback(String query) async {
    try {
      final photonUrl = Uri.parse(
        'https://photon.komoot.io/api/?q=${Uri.encodeComponent(query)}&limit=6',
      );
      final res = await http.get(photonUrl).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final features = (data['features'] as List?) ?? [];
        return features.map((f) {
          final props = f['properties'] as Map<String, dynamic>? ?? {};
          final coords = (f['geometry']?['coordinates'] as List?) ?? [0.0, 0.0];
          final name = props['name'] ?? props['street'] ?? query;
          final city = props['city'] ?? props['town'] ?? props['state'] ?? '';
          final displayName = city.isNotEmpty ? '$name, $city' : name.toString();
          return NominatimPlace(
            displayName: displayName,
            lat: (coords.length > 1 ? coords[1] as num : 0.0).toDouble(),
            lon: (coords.isNotEmpty ? coords[0] as num : 0.0).toDouble(),
          );
        }).where((p) => p.lat != 0.0 && p.lon != 0.0).toList();
      }
    } catch (_) {}
    return [];
  }

  /// Geocodificación inversa para obtener el nombre legible de una coordenada tocada en el mapa
  Future<String> reverseGeocode(LatLng point) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=${point.latitude}&lon=${point.longitude}&format=json&zoom=18&addressdetails=1',
      );
      final res = await http.get(url, headers: {
        'User-Agent': 'MyAutoGuide/1.0 (Mobile App)',
      }).timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>?;
        if (address != null) {
          final road = address['road'] ?? address['pedestrian'] ?? address['suburb'] ?? address['neighbourhood'];
          final city = address['city'] ?? address['town'] ?? address['municipality'] ?? address['state'];
          if (road != null && city != null) {
            return '$road, $city';
          }
          if (road != null) return road.toString();
        }
        return data['display_name']?.toString().split(',').take(2).join(', ') ?? 'Destino seleccionado';
      }
    } catch (_) {}
    return 'Destino en Mapa (${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)})';
  }

  /// Calcula la ruta desde un OSRM Engine público con pasos de giro
  Future<OSRMRoute> calculateRoute(LatLng origin, LatLng destination) async {
    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${origin.longitude},${origin.latitude};'
        '${destination.longitude},${destination.latitude}'
        '?overview=full&geometries=geojson&steps=true',
      );
      final res = await http.get(url).timeout(const Duration(seconds: 12));

      if (res.statusCode == 200) {
        final data = json.decode(res.body);

        if (data['routes'] == null || (data['routes'] as List).isEmpty) {
          throw NavigationLogicException('No se encontró una ruta vial hacia este destino.');
        }

        final route = data['routes'][0];
        final coords = route['geometry']['coordinates'] as List;
        final distMeters = (route['distance'] as num).toDouble();
        final durSeconds = (route['duration'] as num).toDouble();

        final points = coords
            .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
            .toList();

        // Extraer pasos de navegación (maniobras turn-by-turn)
        final List<NavigationStep> steps = [];
        final legs = route['legs'] as List?;
        if (legs != null && legs.isNotEmpty) {
          final rawSteps = legs[0]['steps'] as List?;
          if (rawSteps != null) {
            for (final s in rawSteps) {
              final maneuver = s['maneuver'] as Map<String, dynamic>?;
              final name = s['name'] as String? ?? '';
              final mType = maneuver?['type'] as String? ?? 'turn';
              final modifier = maneuver?['modifier'] as String?;
              final loc = maneuver?['location'] as List?;
              final mLoc = (loc != null && loc.length >= 2)
                  ? LatLng((loc[1] as num).toDouble(), (loc[0] as num).toDouble())
                  : (points.isNotEmpty ? points.first : LatLng(0, 0));

              String instruction = _buildSpanishInstruction(mType, modifier, name);
              steps.add(NavigationStep(
                instruction: instruction,
                distanceMeters: (s['distance'] as num?)?.toDouble() ?? 0.0,
                durationSeconds: (s['duration'] as num?)?.toDouble() ?? 0.0,
                maneuverType: mType,
                modifier: modifier,
                location: mLoc,
              ));
            }
          }
        }

        return OSRMRoute(
          points: points,
          distanceKm: distMeters / 1000,
          durationMin: durSeconds / 60,
          steps: steps,
        );
      } else {
        throw NavigationLogicException('Servidor de rutas no disponible (${res.statusCode})');
      }
    } catch (e) {
      if (e is NavigationLogicException) rethrow;
      throw NavigationLogicException('Error al trazar ruta: $e');
    }
  }

  String _buildSpanishInstruction(String type, String? modifier, String streetName) {
    final street = streetName.isNotEmpty ? ' hacia $streetName' : '';
    switch (type) {
      case 'depart':
        return 'Inicia el recorrido$street';
      case 'arrive':
        return 'Has llegado a tu destino';
      case 'turn':
        if (modifier == 'left') return 'Gira a la izquierda$street';
        if (modifier == 'right') return 'Gira a la derecha$street';
        if (modifier == 'slight left') return 'Gira levemente a la izquierda$street';
        if (modifier == 'slight right') return 'Gira levemente a la derecha$street';
        if (modifier == 'sharp left') return 'Giro pronunciado a la izquierda$street';
        if (modifier == 'sharp right') return 'Giro pronunciado a la derecha$street';
        if (modifier == 'uturn') return 'Haz un giro en U$street';
        return 'Gira$street';
      case 'roundabout':
      case 'rotary':
        return 'Entra a la rotonda$street';
      case 'fork':
        if (modifier == 'left') return 'Mantente a la izquierda en la bifurcación';
        if (modifier == 'right') return 'Mantente a la derecha en la bifurcación';
        return 'Toma la bifurcación$street';
      case 'merge':
        return 'Incorpórate a la vía$street';
      case 'continue':
      default:
        return 'Continúa recto$street';
    }
  }
}
