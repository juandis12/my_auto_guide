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

  factory MotorcycleManual.fromJson(Map<String, dynamic> json) {
    return MotorcycleManual(
      id: json['id']?.toString() ?? '',
      make: json['make']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      year: json['year']?.toString() ?? '',
      type: json['type']?.toString(),
      displacement: json['displacement']?.toString(),
      engine: json['engine']?.toString(),
      power: json['power']?.toString(),
      torque: json['torque']?.toString(),
      compression: json['compression']?.toString(),
      valvesPerCylinder: json['valves_per_cylinder']?.toString(),
      fuelSystem: json['fuel_system']?.toString(),
      fuelControl: json['fuel_control']?.toString(),
      lubrication: json['lubrication']?.toString(),
      cooling: json['cooling']?.toString(),
      gearbox: json['gearbox']?.toString(),
      transmission: json['transmission']?.toString(),
      clutch: json['clutch']?.toString(),
      frame: json['frame']?.toString(),
      frontSuspension: json['front_suspension']?.toString(),
      rearSuspension: json['rear_suspension']?.toString(),
      frontWheelTravel: json['front_wheel_travel']?.toString(),
      rearWheelTravel: json['rear_wheel_travel']?.toString(),
      frontTire: json['front_tire']?.toString(),
      rearTire: json['rear_tire']?.toString(),
      frontBrakes: json['front_brakes']?.toString(),
      rearBrakes: json['rear_brakes']?.toString(),
      seatHeight: json['seat_height']?.toString(),
      groundClearance: json['ground_clearance']?.toString(),
      wheelbase: json['wheelbase']?.toString(),
      fuelCapacity: json['fuel_capacity']?.toString(),
      fuelConsumption: json['fuel_consumption']?.toString(),
      emission: json['emission']?.toString(),
      totalWeight: json['total_weight']?.toString(),
      dryWeight: json['dry_weight']?.toString(),
      starter: json['starter']?.toString(),
      ignition: json['ignition']?.toString(),
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
