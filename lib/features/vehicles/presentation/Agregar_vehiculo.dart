// =============================================================================
// Agregar_vehiculo.dart — REGISTRO DE MOTOCICLETAS
// =============================================================================
//
// Pantalla para agregar una nueva motocicleta al sistema. Toda la lógica y la
// interfaz viven en [VehicleRegistrationView], compartida con el registro de
// automóviles ([AgregarCarroScreen]); aquí solo se fija el tipo de vehículo.
//
// =============================================================================

import 'package:flutter/material.dart';

import 'widgets/vehicle_registration_view.dart';

class AgregarVehiculoScreen extends StatelessWidget {
  const AgregarVehiculoScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const VehicleRegistrationView(kind: VehicleKind.moto);
}
