# 🐟 MiroFish Multi-Agent Simulation Report: MY AUTO GUIDE

**Puntuación de Adopción Global:** `90.1 / 100`  
**Fecha de Ejecución:** `2026-10-28 18:24:09`

## 👥 Personas Evaluadas

- **Carlos (22)** (Motero Novato (Yamaha MT-15)) — Nivel Técnico: Alto | Mecánico: Bajo
  - *Objetivos:* Ver odómetro en vivo, Saber cuándo lubricar cadena, No gastar de más
  - *Sesgo:* Sensible a costos de mantenimiento, ama las métricas visuales pero no sabe de calibración.

- **Andrés (38)** (Conductor Ejecutivo (Mazda 3)) — Nivel Técnico: Medio | Mecánico: Bajo-Medio
  - *Objetivos:* Alertas anticipadas de SOAT/RUNT, Navegación GPS fluida, Historial de gastos
  - *Sesgo:* Muy ocupado, le teme a las multas de tránsito y olvido de SOAT/Tecno.

- **Don Hernando (54)** (Mecánico Veterano de Taller) — Nivel Técnico: Bajo | Mecánico: Experto
  - *Objetivos:* Verificar datos de sensores en vivo (RPM, Temp, Voltaje), Validar diagnóstico de la IA
  - *Sesgo:* Escéptico de las apps que 'reemplazan' al mecánico. Exige ver códigos DTC OBD-II puros.

- **Paola (29)** (Usuaria No Técnica (Carro Urbano)) — Nivel Técnico: Medio | Mecánico: Nulo
  - *Objetivos:* Explicaciones sin tecnicismos, Saber si el carro puede rodar o debe detenerse
  - *Sesgo:* Se asusta con los testigos luminosos del tablero y odia los manuales largos.

## 📊 Hallazgos por Ronda de Simulación

### Ronda 1: Onboarding & Configuración de Vehículo
*Contexto:* El usuario registra su vehículo, kilometraje inicial y enlaza el escáner Bluetooth OBD-II.

- **Carlos (22)** (`90/100`): Registra su MT-15 usando el modelo 3D y vista 360°. Muy satisfecho con el velocímetro digital.
  - ⚠️ *Punto de Fricción:* Duda sobre qué valor poner en 'intervalo de cadena' (falta recomendación automática por fabricante).
- **Andrés (38)** (`85/100`): Registra su Mazda 3 y carga fotos de SOAT y Tarjeta de Propiedad.
  - ⚠️ *Punto de Fricción:* La pantalla de RUNT Webview tardó en cargar por lentitud del servidor oficial.
- **Don Hernando (54)** (`80/100`): Prueba la conexión Bluetooth con un escáner genérico ELM327 v1.5.
  - ⚠️ *Punto de Fricción:* Si el Bluetooth no se vincula en el primer intento, el mensaje de error debe indicar 'Revisar switch de encendido'.
- **Paola (29)** (`88/100`): Descarga la app tras recomendación. Entiende el semáforo de Salud ISH (92%).
  - ⚠️ *Punto de Fricción:* Tuvo dudas al ingresar el número de cédula (se requirió explicar el cifrado seguro).

### Ronda 2: Estrés Operativo: Pérdida de Señal GPS y Falla de Motor
*Contexto:* Durante un viaje se cruza un túnel sin señal GPS y salta un código DTC P0300 (Fallo de encendido).

- **Carlos (22)** (`88/100`): Iba en ruta y el mapa entra en túnel. La app entra en modo offline y estima velocidad por acelerómetro.
  - ⚠️ *Punto de Fricción:* Al salir del túnel, la reconciliación del odómetro debe evitar saltos bruscos en el kilometraje.
- **Andrés (38)** (`84/100`): Se enciende el testigo Check Engine. La app le envía una notificación inmediata con el código P0300.
  - ⚠️ *Punto de Fricción:* Necesita un indicador de severidad: ¿puedo seguir conduciendo 20 km hasta mi destino o debo parar ya?
- **Don Hernando (54)** (`92/100`): Revisa la pantalla de telemetría OBD-II para cotejar las RPM con el fallo de cilindro.
  - ⚠️ *Punto de Fricción:* Aplaude ver datos en vivo (RPM, Voltaje, Temp), pero pide un botón para 'Borrar Códigos DTC'.
- **Paola (29)** (`91/100`): Entra en pánico al ver el testigo rojo en la app.
  - ⚠️ *Punto de Fricción:* La app calmó la situación mostrando 'Alerta Leve: posible falla en bujía, conduce con precaución'. Excelente UX.

### Ronda 3: Resolución con Experto IA (Gemini) y Cierre de Mantenimiento
*Contexto:* El usuario abre el chat con el Experto Mecánico IA para resolver la duda y agenda taller.

- **Carlos (22)** (`98/100`): Pregunta a la IA qué aceite usar para su MT-15. La IA responde con la viscosidad exacta (Yamalube 10W-40) y volumen.
  - ⚠️ *Punto de Fricción:* Ninguna. Quedó sorprendido con la precisión.
- **Andrés (38)** (`96/100`): Verifica vencimiento de SOAT. La app le avisa con 30 días de anticipación con link directo a compra oficial.
  - ⚠️ *Punto de Fricción:* Excelente. Evitó una infracción de tránsito de $1.300.000 COP.
- **Don Hernando (54)** (`94/100`): Pone a prueba a la IA preguntando por tolerancias de holgura de válvulas.
  - ⚠️ *Punto de Fricción:* La IA cita el manual de taller correctamente. Hernando acepta registrar su taller en el Marketplace.
- **Paola (29)** (`95/100`): Pregunta '¿Qué hago si huele a gasolina?'. La IA le da 3 pasos de seguridad inmediatos.
  - ⚠️ *Punto de Fricción:* Se sintió acompañada y respaldada. Considera la app indispensable.

## 💡 Recomendaciones de Ingeniería (Nivel CTO)

- 1. Autocompletar intervalos de mantenimiento recomendados según marca/cilindrada en el onboarding.
- 2. Agregar semáforo de severidad para códigos DTC OBD-II ('Detener vehículo de inmediato' vs 'Conducir con precaución al taller').
- 3. En navegación por túneles (sin GPS), asegurar que el algoritmo de Dead Reckoning suavice el cálculo de kilometraje.
- 4. Proveer un botón de 'Borrado de Códigos DTC' tras confirmar la reparación con el mecánico.
- 5. Mantener la pantalla de consulta RUNT con caché local offline para evitar caídas del servidor estatal.
