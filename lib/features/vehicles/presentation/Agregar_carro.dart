// =============================================================================
// Agregar_carro.dart — REGISTRO DE AUTOMÓVILES
// =============================================================================
//
// Pantalla para agregar un nuevo automóvil al sistema. Toda la lógica y la
// interfaz viven en [VehicleRegistrationView], compartida con el registro de
// motocicletas ([AgregarVehiculoScreen]); aquí solo se fija el tipo de
// vehículo.
//
// =============================================================================

import 'package:flutter/material.dart';

import 'widgets/vehicle_registration_view.dart';

class AgregarCarroScreen extends StatelessWidget {
  const AgregarCarroScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const VehicleRegistrationView(kind: VehicleKind.carro);
}
