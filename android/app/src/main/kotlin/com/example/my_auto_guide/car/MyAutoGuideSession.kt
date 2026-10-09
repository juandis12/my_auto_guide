package com.example.my_auto_guide.car

import android.content.Intent
import androidx.car.app.Screen
import androidx.car.app.Session

class MyAutoGuideSession : Session() {
    override fun onCreateScreen(intent: Intent): Screen {
        // Devuelve la pantalla principal de Android Auto
        return MainDashboardScreen(carContext)
    }
}
