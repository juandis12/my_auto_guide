package com.example.my_auto_guide.car

import androidx.car.app.CarAppService
import androidx.car.app.Session
import androidx.car.app.validation.HostValidator

class MyAutoGuideCarAppService : CarAppService() {
    override fun createHostValidator(): HostValidator {
        // Permitir todos los hosts (tanto en depuración como en release/sideload)
        // para evitar que Android Auto rechace la conexión con "App no disponible"
        return HostValidator.ALLOW_ALL_HOSTS_VALIDATOR
    }

    override fun onCreateSession(sessionInfo: androidx.car.app.SessionInfo): Session {
        return MyAutoGuideSession()
    }
}
