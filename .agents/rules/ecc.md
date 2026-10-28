# ECC (Everything Claude Code) — Protocolo Obligatorio Permanente

> Este documento activa y hace obligatorio el framework **ECC (Everything Claude Code / Agent Harness Performance Optimization System)** para Google Antigravity en **MY AUTO GUIDE**. Debe aplicarse de manera estricta y sin excepción en cada requerimiento.

---

## ⚡ 1. Principio Rector de ECC

Toda interacción, refactorización, creación de características o resolución de bugs debe ejecutarse bajo el pipeline de 5 fases de ECC:

```
[0. Research & Reuse] ➔ [1. Plan First] ➔ [2. TDD / Quality Gate] ➔ [3. Implementation] ➔ [4. Code Review & Verify]
```

Está terminantemente prohibido saltar directamente al código sin completar el análisis previo de impacto y arquitectura.

---

## 🔄 2. Fases del Flujo de Trabajo ECC

### Fase 0: Investigación y Reutilización (Research & Reuse)
- **Inspeccionar antes de crear:** Verificar si ya existen utilidades, widgets, servicios o proveedores en `lib/core/` o `lib/features/`.
- **Dependencias probadas:** Consultar `pubspec.yaml` antes de reinventar ruedas; priorizar paquetes consolidados ya instalados (`supabase_flutter`, `flutter_map`, `flutter_blue_plus`, `google_generative_ai`).

### Fase 1: Planificación (Plan First)
- Todo cambio estructural requiere desglose previo:
  1. **Análisis:** ¿Qué problema resuelve o qué feature implementa?
  2. **Arquitectura:** Ubicación estricta (UI ➔ Provider ➔ Service ➔ Data Layer / Supabase).
  3. **Riesgos:** Identificación de posibles memory leaks, bloqueos de UI, consumo de batería por GPS o desincronización offline.

### Fase 2: TDD y Criterios de Prueba (TDD Approach)
- Definir las condiciones de fallo y éxito antes de modificar código.
- En lógica crítica (cálculo de odómetro, sincronización GPS, escaneo OBD-II, cifrado de tokens):
  - Escribir o definir pruebas unitarias / mocks.
  - Asegurar validación en los 4 casos límite: sin internet, GPS denegado, dispositivo Bluetooth desconectado, datos nulos o corruptos.

### Fase 3: Implementación Limpia y Segura (Clean Implementation)
- **Inmutabilidad estricta:** Retornar copias actualizadas (`copyWith`), nunca mutar estados en memoria directamente.
- **KISS, DRY & YAGNI:** Solución más simple y modular. Sin código especulativo.
- **Límites de archivo:** Ningún widget o clase debe sobrepasar 400-500 líneas sin modularizar sub-widgets o servicios.
- **Manejo integral de errores:** Prohibido el uso de bloques `catch` vacíos. Todo error debe registrarse en Sentry o manejarse con un estado UI amigable.

### Fase 4: Auditoría y Revisión de Código (Code Review)
- Tras implementar cualquier cambio, auditar activamente:
  - 🔍 **Seguridad:** No exponer API keys, validar datos en fronteras, uso de `flutter_secure_storage`.
  - ⚡ **Rendimiento:** Rebuilds innecesarios de Flutter, listeners no removidos, streams no cerrados (`dispose()`).
  - 🔋 **Batería:** Frecuencia y precisión de geolocalización adaptativa.

---

## 📚 3. Reglas Específicas Activas en el Proyecto

Las siguientes reglas instaladas en `.agents/rules/` son de cumplimiento obligatorio:

| Dominio | Reglas Aplicables |
| :--- | :--- |
| **Flutter / Dart** | [`.agents/rules/dart-coding-style.md`](file:///d:/Proyectos/my_auto_guide/.agents/rules/dart-coding-style.md)<br>[`.agents/rules/dart-security.md`](file:///d:/Proyectos/my_auto_guide/.agents/rules/dart-security.md)<br>[`.agents/rules/dart-testing.md`](file:///d:/Proyectos/my_auto_guide/.agents/rules/dart-testing.md) |
| **Android / Kotlin** | [`.agents/rules/kotlin-coding-style.md`](file:///d:/Proyectos/my_auto_guide/.agents/rules/kotlin-coding-style.md)<br>[`.agents/rules/kotlin-patterns.md`](file:///d:/Proyectos/my_auto_guide/.agents/rules/kotlin-patterns.md)<br>[`.agents/rules/kotlin-security.md`](file:///d:/Proyectos/my_auto_guide/.agents/rules/kotlin-security.md)<br>[`.agents/rules/kotlin-testing.md`](file:///d:/Proyectos/my_auto_guide/.agents/rules/kotlin-testing.md) |
| **Python / Tools** | [`.agents/rules/python-coding-style.md`](file:///d:/Proyectos/my_auto_guide/.agents/rules/python-coding-style.md)<br>[`.agents/rules/python-security.md`](file:///d:/Proyectos/my_auto_guide/.agents/rules/python-security.md) |
| **Común & Arquitectura** | [`.agents/rules/common-development-workflow.md`](file:///d:/Proyectos/my_auto_guide/.agents/rules/common-development-workflow.md)<br>[`.agents/rules/common-coding-style.md`](file:///d:/Proyectos/my_auto_guide/.agents/rules/common-coding-style.md)<br>[`.agents/rules/common-git-workflow.md`](file:///d:/Proyectos/my_auto_guide/.agents/rules/common-git-workflow.md) |

---

## 🤖 4. Agentes Especializados Disponibles

Cuando un requerimiento involucre auditoría técnica o refactorización especializada, se deben consultar las directrices de los agentes correspondientes en `.agents/agents/`:
- `flutter-reviewer` & `dart-build-resolver`: Para arquitectura de UI y widgets en Flutter.
- `kotlin-reviewer` & `kotlin-build-resolver`: Para Android Auto, servicios en segundo plano y canal nativo.
- `security-reviewer`: Para auditoría de almacenamiento seguro, tokens de sesión y llamadas a Supabase.
- `performance-optimizer`: Para optimización de FPS, streams de GPS y consumo de memoria.
- `tdd-guide`: Para formulación y ejecución de suites de pruebas automáticas.
