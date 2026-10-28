---
name: mirofish
description: Multi-agent swarm simulation & scenario testing engine based on MiroFish (666ghj/MiroFish & gateszhangc/mirofish-skill). Spawns diverse personas with distinct incentives, biases, and memories to simulate user behavior, stress-test application UX, predict adoption hurdles, and discover edge cases over multiple interaction rounds. Use when testing an application with simulated users, stress-testing workflows, running counterfactual what-if scenarios, or assessing market/user reactions.
license: MIT
compatibility: Google Antigravity, Claude Code, Python runtime
metadata:
  version: "1.0"
  upstream: https://github.com/666ghj/MiroFish
---

# MiroFish — Multi-Agent Simulation Engine for Application Testing

MiroFish is an open-source swarm intelligence engine that rehearses the future. It extracts system entities into a knowledge graph, spawns autonomous AI personas with conflicting priorities and memory, and simulates round-based multiplayer interactions to discover emergent bugs, UX friction, and user adoption barriers before real-world rollout.

---

## 🎯 When to Use This Skill

Activate MiroFish whenever you need to:
1. **User Persona Testing:** Test how distinct user segments (e.g. non-tech car owners, professional mechanics, high-speed motorcycle riders, fleet managers) interact with your application features.
2. **Edge-Case & Failure Mode Discovery:** Simulate volatile conditions (GPS signal loss in tunnels, OBD-II Bluetooth disconnections, out-of-date SOAT documents, contradictory AI mechanic diagnoses).
3. **UX & Friction Audits:** Identify where users abandon journeys (complex onboarding, overwhelming telemetries, confusing maintenance intervals).
4. **Market & Feature Adoption Forecast:** Predict whether a new feature (like OBD-II telemetry or AI Mechanic chat) will be embraced, ignored, or mistrusted.

---

## 🔬 The 5-Stage MiroFish Simulation Lifecycle

```
[1. Seed the World] ➔ [2. Map Graph Dynamics] ➔ [3. Spawn Personas] ➔ [4. Multi-Round Simulation] ➔ [5. Intelligence Report]
```

### Stage 1: Seed the World
Define the core application scope, active features, environment constraints, and test objectives in plain language. For **MY AUTO GUIDE**, seeds include:
- Vehicle Management (Car / Motorcycle garage).
- Live Telemetry & Bluetooth OBD-II Diagnosis.
- GPS Navigation with automatic odometer accumulation.
- Google Gemini AI Mechanic Assistant.
- Legal document tracking (SOAT, Tecnomecánica, RUNT/SIMIT).

### Stage 2: Map Graph Dynamics
Extract key entities, friction points, and value exchanges into a conflict matrix:
- **Entities:** Drivers, Vehicles, Sensors (ELM327 BLE, GPS, Accelerometer), Backend (Supabase, Sentry), Legal Entities (RUNT, SIMIT), AI Engine (Gemini).
- **Potential Tensions:** Privacy concerns (GPS tracking), sensor reliability, battery drain, mechanic distrust of AI suggestions.

### Stage 3: Spawn Diverse Personas
Generate realistic personas with distinct biases, technical literacy, and incentives:
1. **Persona A: "El Motero Novato" (Carlos, 22)** — Conduce Yamaha MT-15. Poco conocimiento mecánico, alta adopción móvil, sensible a costos de mantenimiento.
2. **Persona B: "El Conductor Corporativo" (Andrés, 38)** — Conduce Mazda 3. Valora su tiempo, busca cero multas RUNT y alertas de vencimiento de SOAT/Tecno.
3. **Persona C: "El Mecánico Escéptico" (Don Hernando, 54)** — Propietario de taller tradicional. Desconfía de diagnósticos automáticos por IA y exige ver datos brutos OBD-II.
4. **Persona D: "La Usuaria No Técnica" (Paola, 29)** — Odia tecnicismos. Se asusta al ver un testigo de motor encendido y necesita recomendaciones en lenguaje claro.

### Stage 4: Run the Multi-Round Rehearsal
Simulate sequential interaction rounds across personas responding to application events:
- **Round 1 (Onboarding & Initial Use):** First impression, garage setup, document uploads.
- **Round 2 (Stress Event / Incident):** Simulated check-engine light, Bluetooth link drop, or sudden GPS tunnel outage.
- **Round 3 (Resolution & Retention):** AI mechanic advice review, action taken, and return to the app.

### Stage 5: Read the Intelligence Report
Output a structured report surfacing:
- **Adoption Trajectory & Confidence Score.**
- **Top UX Friction Points Ranked by Severity (Critical, High, Medium).**
- **Edge Cases & Failure Modes Discovered.**
- **Actionable Engineering Recommendations.**

---

## 🚀 Automated Testing Runner

You can execute an automated MiroFish multi-agent test against the current application using the bundled simulation runner:

```powershell
python .agents/skills/mirofish/scripts/simulate_app_test.py
```

This runs a local, zero-token-waste multi-agent simulation that evaluates **MY AUTO GUIDE** across real user journeys and generates:
- `test_simulation_report.json`
- `test_simulation_report.md`
