package com.example.my_auto_guide.car

import androidx.car.app.CarContext
import androidx.car.app.Screen
import androidx.car.app.model.Action
import androidx.car.app.model.ActionStrip
import androidx.car.app.model.CarColor
import androidx.car.app.model.Pane
import androidx.car.app.model.PaneTemplate
import androidx.car.app.model.Row
import androidx.car.app.model.Template

class MainDashboardScreen(carContext: CarContext) : Screen(carContext) {

    override fun onGetTemplate(): Template {
        // Filas de información (Telemetría / Scanner)
        val row1 = Row.Builder()
            .setTitle("Scanner OBD2: Desconectado")
            .addText("Esperando conexión Bluetooth...")
            .build()

        val row2 = Row.Builder()
            .setTitle("Salud del Vehículo")
            .addText("Índice de Salud: 100% (Óptimo)")
            .build()

        val pane = Pane.Builder()
            .addRow(row1)
            .addRow(row2)
            .build()

        // Botones de acción en la pantalla del auto
        val actionStrip = ActionStrip.Builder()
            .addAction(
                Action.Builder()
                    .setTitle("Escanear")
                    .setBackgroundColor(CarColor.BLUE)
                    .setOnClickListener {
                        // Aquí enviaríamos un mensaje a Flutter vía MethodChannel
                        // para que inicie el escaneo Bluetooth de fondo
                    }
                    .build()
            )
            .build()

        return PaneTemplate.Builder(pane)
            .setTitle("My Auto Guide - Dashboard")
            .setHeaderAction(Action.APP_ICON)
            .setActionStrip(actionStrip)
            .build()
    }
}
