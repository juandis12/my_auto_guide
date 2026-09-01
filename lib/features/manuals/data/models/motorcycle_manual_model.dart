class MotorcycleManual {
  final String id;
  final String make;
  final String model;
  final String year;
  final String? type;
  final String? displacement;
  final String? engine;
  final String? power;
  final String? torque;
  final String? compression;
  final String? valvesPerCylinder;
  final String? fuelSystem;
  final String? fuelControl;
  final String? lubrication;
  final String? cooling;
  final String? gearbox;
  final String? transmission;
  final String? clutch;
  final String? frame;
  final String? frontSuspension;
  final String? rearSuspension;
  final String? frontWheelTravel;
  final String? rearWheelTravel;
  final String? frontTire;
  final String? rearTire;
  final String? frontBrakes;
  final String? rearBrakes;
  final String? seatHeight;
  final String? groundClearance;
  final String? wheelbase;
  final String? fuelCapacity;
  final String? fuelConsumption;
  final String? emission;
  final String? totalWeight;
  final String? dryWeight;
  final String? starter;
  final String? ignition;
  final String? topSpeed;
  final String? manualPdfUrl;
  final Map<String, dynamic>? rawSpecs;

  const MotorcycleManual({
    required this.id,
    required this.make,
    required this.model,
    required this.year,
    this.type,
    this.displacement,
    this.engine,
    this.power,
    this.torque,
    this.compression,
    this.valvesPerCylinder,
    this.fuelSystem,
    this.fuelControl,
    this.lubrication,
    this.cooling,
    this.gearbox,
    this.transmission,
    this.clutch,
    this.frame,
    this.frontSuspension,
    this.rearSuspension,
    this.frontWheelTravel,
    this.rearWheelTravel,
    this.frontTire,
    this.rearTire,
    this.frontBrakes,
    this.rearBrakes,
    this.seatHeight,
    this.groundClearance,
    this.wheelbase,
    this.fuelCapacity,
    this.fuelConsumption,
    this.emission,
    this.totalWeight,
    this.dryWeight,
    this.starter,
    this.ignition,
    this.topSpeed,
    this.manualPdfUrl,
    this.rawSpecs,
  });

  static String? _translate(String? text) {
    if (text == null || text.trim().isEmpty) return text;
    String res = text.trim();

    // Reemplazos de traducción técnica al español
    final replacements = <Pattern, String>{
      RegExp(r'\bnaked bike\b|\bnaked\b', caseSensitive: false): 'Naked / Urbana',
      RegExp(r'\bsuper sport\b|\bsupersport\b', caseSensitive: false): 'Super Sport (Pista)',
      RegExp(r'\bsport\b', caseSensitive: false): 'Deportiva',
      RegExp(r'\btouring\b', caseSensitive: false): 'Turismo / Viajera',
      RegExp(r'\badventure\b', caseSensitive: false): 'Aventura / Doble Propósito',
      RegExp(r'\benduro\b|\boffroad\b|\boff-road\b', caseSensitive: false): 'Enduro / Todoterreno',
      RegExp(r'\bcross\b|\bmotocross\b', caseSensitive: false): 'Motocross',
      RegExp(r'\bcustom\b|\bcruiser\b', caseSensitive: false): 'Custom / Chopper',
      RegExp(r'\bscooter\b', caseSensitive: false): 'Scooter / Automática',
      RegExp(r'\bsingle cylinder\b', caseSensitive: false): 'Monocilíndrico',
      RegExp(r'\btwo cylinder\b|\btwin\b', caseSensitive: false): 'Bicilíndrico',
      RegExp(r'\bthree cylinder\b|\btriple\b', caseSensitive: false): 'Tricilíndrico',
      RegExp(r'\bfour cylinder\b|\bfour-cylinder\b', caseSensitive: false): 'Tetracilíndrico (4 cilindros)',
      RegExp(r'\bfour-stroke\b|\b4-stroke\b', caseSensitive: false): '4 tiempos',
      RegExp(r'\btwo-stroke\b|\b2-stroke\b', caseSensitive: false): '2 tiempos',
      RegExp(r'\bliquid\b|\bliquid cooled\b|\bwater\b', caseSensitive: false): 'Líquida (Radiador)',
      RegExp(r'\bair\b|\bair cooled\b', caseSensitive: false): 'Por aire natural',
      RegExp(r'\boil\b|\boil cooled\b', caseSensitive: false): 'Por aire y radiador de aceite',
      RegExp(r'\belectric & kick\b|\belectric and kick\b', caseSensitive: false): 'Eléctrico y Pedal',
      RegExp(r'\belectric\b', caseSensitive: false): 'Eléctrico',
      RegExp(r'\bkick\b', caseSensitive: false): 'Pedal (Patada)',
      RegExp(r'(\d+)-speed', caseSensitive: false): r'$1 velocidades',
      RegExp(r'\bautomatic\b', caseSensitive: false): 'Automática (CVT)',
      RegExp(r'\bmanual\b', caseSensitive: false): 'Manual',
      RegExp(r'\bchain\b(?:\s*\(final drive\))?', caseSensitive: false): 'Cadena de transmisión',
      RegExp(r'\bbelt\b(?:\s*\(final drive\))?', caseSensitive: false): 'Correa dentada',
      RegExp(r'\bshaft\b(?:\s*\(final drive\))?', caseSensitive: false): 'Cardán',
      RegExp(r'\bwet, multi-plate\b|\bwet multi-plate\b', caseSensitive: false): 'Multidisco en baño de aceite',
      RegExp(r'\binjection\b|\belectronic injection\b', caseSensitive: false): 'Inyección Electrónica (FI)',
      RegExp(r'\bcarburettor\b|\bcarburetor\b', caseSensitive: false): 'Carburador',
      RegExp(r'\bsingle disc\b', caseSensitive: false): 'Disco individual',
      RegExp(r'\bdouble disc\b|\bdual disc\b', caseSensitive: false): 'Doble disco',
      RegExp(r'\bexpanding brake\b|\bdrum brake\b|\bdrum\b', caseSensitive: false): 'Tambor',
      RegExp(r'\bhydraulic\b', caseSensitive: false): 'hidráulico',
      RegExp(r'\bwith abs\b|\babs\b', caseSensitive: false): 'con sistema ABS',
      RegExp(r'\btelescopic forks?\b', caseSensitive: false): 'Horquilla telescópica hidráulica',
      RegExp(r'\bupside-down\b|\busd fork\b|\binverted fork\b', caseSensitive: false): 'Horquilla invertida (USD)',
      RegExp(r'\bmonoshock\b|\bmono-shock\b', caseSensitive: false): 'Monoamortiguador ajustable (Monoshock)',
      RegExp(r'\btwin shock\b|\bdual shock\b', caseSensitive: false): 'Doble amortiguador trasero',
    };

    for (final entry in replacements.entries) {
      res = res.replaceAllMapped(entry.key, (m) {
        if (m.groupCount >= 1 && m.group(1) != null) {
          return entry.value.replaceAll(r'$1', m.group(1)!);
        }
        return entry.value;
      });
    }

    res = res.replaceAll(RegExp(r'\s*\(final drive\)', caseSensitive: false), '')
             .replaceAll(RegExp(r'\s*\(drum brake\)', caseSensitive: false), '')
             .replaceAll(RegExp(r'\s*\(tambor brake\)', caseSensitive: false), '')
             .replaceAll(RegExp(r'\s*\(disc brake\)', caseSensitive: false), '')
             .replaceAll(' ,', ',')
             .trim();

    return res;
  }

  factory MotorcycleManual.fromJson(Map<String, dynamic> json) {
    return MotorcycleManual(
      id: json['id']?.toString() ?? '',
      make: json['make']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      year: json['year']?.toString() ?? '',
      type: _translate(json['type']?.toString()),
      displacement: json['displacement']?.toString(),
      engine: _translate(json['engine']?.toString()),
      power: json['power']?.toString(),
      torque: json['torque']?.toString(),
      compression: json['compression']?.toString(),
      valvesPerCylinder: json['valves_per_cylinder']?.toString(),
      fuelSystem: _translate(json['fuel_system']?.toString()),
      fuelControl: _translate(json['fuel_control']?.toString()),
      lubrication: _translate(json['lubrication']?.toString()),
      cooling: _translate(json['cooling']?.toString()),
      gearbox: _translate(json['gearbox']?.toString()),
      transmission: _translate(json['transmission']?.toString()),
      clutch: _translate(json['clutch']?.toString()),
      frame: _translate(json['frame']?.toString()),
      frontSuspension: _translate(json['front_suspension']?.toString()),
      rearSuspension: _translate(json['rear_suspension']?.toString()),
      frontWheelTravel: json['front_wheel_travel']?.toString(),
      rearWheelTravel: json['rear_wheel_travel']?.toString(),
      frontTire: json['front_tire']?.toString(),
      rearTire: json['rear_tire']?.toString(),
      frontBrakes: _translate(json['front_brakes']?.toString()),
      rearBrakes: _translate(json['rear_brakes']?.toString()),
      seatHeight: json['seat_height']?.toString(),
      groundClearance: json['ground_clearance']?.toString(),
      wheelbase: json['wheelbase']?.toString(),
      fuelCapacity: json['fuel_capacity']?.toString(),
      fuelConsumption: json['fuel_consumption']?.toString(),
      emission: _translate(json['emission']?.toString()),
      totalWeight: json['total_weight']?.toString(),
      dryWeight: json['dry_weight']?.toString(),
      starter: _translate(json['starter']?.toString()),
      ignition: _translate(json['ignition']?.toString()),
      topSpeed: json['top_speed']?.toString(),
      manualPdfUrl: json['manual_pdf_url']?.toString(),
      rawSpecs: json['raw_specs'] is Map<String, dynamic> ? json['raw_specs'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'make': make,
      'model': model,
      'year': year,
      'type': type,
      'displacement': displacement,
      'engine': engine,
      'power': power,
      'torque': torque,
      'compression': compression,
      'valves_per_cylinder': valvesPerCylinder,
      'fuel_system': fuelSystem,
      'fuel_control': fuelControl,
      'lubrication': lubrication,
      'cooling': cooling,
      'gearbox': gearbox,
      'transmission': transmission,
      'clutch': clutch,
      'frame': frame,
      'front_suspension': frontSuspension,
      'rear_suspension': rearSuspension,
      'front_wheel_travel': frontWheelTravel,
      'rear_wheel_travel': rearWheelTravel,
      'front_tire': frontTire,
      'rear_tire': rearTire,
      'front_brakes': frontBrakes,
      'rear_brakes': rearBrakes,
      'seat_height': seatHeight,
      'ground_clearance': groundClearance,
      'wheelbase': wheelbase,
      'fuel_capacity': fuelCapacity,
      'fuel_consumption': fuelConsumption,
      'emission': emission,
      'total_weight': totalWeight,
      'dry_weight': dryWeight,
      'starter': starter,
      'ignition': ignition,
      'top_speed': topSpeed,
      'manual_pdf_url': manualPdfUrl,
      'raw_specs': rawSpecs,
    };
  }
}
