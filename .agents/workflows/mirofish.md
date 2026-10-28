---
description: Run MiroFish multi-agent swarm simulation to test application UX, discover edge cases, and rehearse user adoption scenarios
---

# /mirofish

Execute a multi-agent simulation test against **MY AUTO GUIDE** to stress-test features, uncover UX friction, and predict user reactions.

## Steps

1. **Define Test Scenario:**
   - Onboarding & Garage setup?
   - OBD-II Bluetooth & Telemetry failures?
   - Offline GPS navigation & tunnel dead-reckoning?
   - AI Mechanic advice & diagnosis accuracy?

2. **Select or Spawn Personas:**
   - Novice motorcycle rider (cost & maintenance sensitive)
   - Executive car driver (busy, legal document & fines focus)
   - Senior mechanical workshop owner (skeptical of AI, DTC code focused)
   - Non-technical driver (afraid of warning lights, seeks simple guidance)

3. **Execute Simulation Run:**
   ```powershell
   python .agents/skills/mirofish/scripts/simulate_app_test.py
   ```

4. **Review Intelligence Report:**
   - Inspect `.agents/skills/mirofish/simulation_report.md`
   - Apply engineering recommendations to the codebase.
