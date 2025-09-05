# DC Motor Advanced Control (Pololu 37D + STM32F4)

State-feedback (LQR) and torque control for a brushed DC geared motor using an STM32F4 microcontroller. From modeling and identification to embedded implementation and validation.

<div align="center">
  <img src="https://github.com/user-attachments/assets/f965d611-9de3-414a-be8f-11bec885afba" alt="Hardware setup" />
</div>

---

## 🚀 Highlights

* Dual control layers: high‑performance position/velocity LQR + dedicated torque (current) loop.
* Observer + anti‑windup + discrete implementation for embedded real‑time execution (84 MHz Cortex‑M4).
* Full V‑Model engineering workflow (modeling, MIL / SIL / PIL / HIL traces) – see `report.pdf`.
* MATLAB / Simulink models mirrored by hand‑crafted C firmware (no auto‑code generation dependency for core logic).
* Data acquisition & rapid tuning scripts (UART → MATLAB live plotting).
* Modular encoder interface (quadrature Hall, 8400 counts / rev at output shaft with gearbox).

---

## 📋 Table of Contents
1. Motivation & Goals
2. System Overview (Simulink Models)
3. Hardware Kit
4. Control Design Overview
5. Repository Structure
6. Quick Start
7. Building & Flashing (STM32)
8. Results Snapshot

---

## 1. Motivation & Goals
Design and validate a robust, high‑fidelity control stack for a geared DC motor able to: (a) track position/velocity references with minimal overshoot and (b) deliver commanded torque (via current shaping) under load disturbances.

## 2. System Overview (Simulink Models)
The architectural block diagram is defined directly in the provided Simulink models. Refer to these files for the authoritative structure of the cascaded loops, observer integration, and PIL/SIL flow:

Position / Outer Loop Models:
* `position/MIL_pos_pade_observer_discrete_antiwindup.slx` – Full MIL validation (observer + anti‑windup + discrete implementation).
* `position/SIL_PIL_pos.slx` / `position/SIL_PIL_extern_pos.slx` – Software / Processor‑in‑the‑Loop integration with embedded code.

Torque / Inner Loop Models:
* `torque/MIL_Torque_controller.slx` – Torque (current) control design & tuning.
* `torque/SIL_PIL_torque.slx` / `torque/SIL_PIL_torque_extern.slx` – SIL / PIL validation of torque layer.
* `torque/motor_model.slx` – Electrical + mechanical plant (R, L, J, friction, gear reduction).

Support & Shared Components:
* `quadratureEncoder_module/stm_qeplib.slx` – Encoder (QEP) interface library.
* `Inductance/Tuning_L.slx` – Inductance identification workflow.
* `position/observer.m`, `Inductance/Inductance.m`, `Sensor_calibration/sensor_calibration.m` – Scripted identification / calibration steps feeding model parameters.

## 3. Hardware Kit
| Component | Notes |
|-----------|-------|
| STM32F401RE Nucleo | ARM Cortex‑M4 @ 84 MHz, UART, timers, ST‑Link |
| Pololu 37D Gearmotor | 12 V brushed DC, 131.25:1 gearbox, 64 CPR internal encoder → 8400 counts/output rev |
| X-NUCLEO‑IHM04A1 | Dual H‑bridge driver (direction + PWM) |
| ACS714 Current Sensor | Hall‑effect linear current sensing |
| Wheel + Mounting Kit | Mechanical load + fixture |

## 4. Control Design Overview
Core steps (mirrored by scripts / models in repo):
* Parameter Identification: electrical (R, L via `Inductance.m`) & mechanical (gear ratio, friction, inertia) using captured current/voltage/speed datasets.
* State Model: continuous + discretized (zero‑order hold & Pade for delays where applicable).
* Outer Loop: LQR tuned for weighted compromise between settling time, steady error, and actuation energy.
* Inner Torque Loop: PI / LQR hybrid (depending on configuration) ensuring current → torque linearization.
* Observer: reconstructs unmeasured states (e.g. motor shaft speed) & compensates gearbox dynamics.
* Anti‑Windup: conditional integral clamping on saturation (implemented in discrete form for MCU tick).
* Validation Stages: MIL (pure Simulink) → SIL / PIL (`SIL_PIL_*` models) → on‑board tests logged over UART.

## 5. Repository Structure (Key Folders)
| Path | Purpose |
|------|---------|
| `direct_coding/Position_Controller` | Embedded firmware for position/velocity LQR controller |
| `direct_coding/TorqueController` | Embedded torque (current) control project |
| `position/*.slx` | Position control Simulink models (MIL / SIL / PIL) |
| `torque/*.slx` | Torque & motor electrical dynamics models |
| `quadratureEncoder_module/` | Reusable encoder (QEP) module (C++ / Simulink lib) |
| `Inductance/` | Inductance identification scripts & datasets |
| `Sensor_calibration/` | Current sensor calibration routine & baseline data |
| `readFromCOM/` | MATLAB scripts for serial streaming & logging |
| `motor_data/` | Captured reference vs response datasets |
| `report.pdf` | Full engineering report (derivations & analysis) |

## 6. Quick Start
Prerequisites:
* STM32CubeIDE
* MATLAB / Simulink (Control System; versions 2020b+ tested)
* USB cable for Nucleo; lab power supply (≤ 12 V)

Clone:
```
git clone https://github.com/my-rice/DC-Motor-Control.git
cd DC-Motor-Control
```

Open the desired Simulink model (e.g. `position/MIL_pos_pade_observer_discrete_antiwindup.slx`) to explore the design.

## 7. Building & Flashing (STM32)

To test the hand-crafted embedded firmware:
1. Import `direct_coding` into STM32CubeIDE (File → Import → Existing Projects).  
2. Configure clock & peripherals (already set in `.ioc` files; regenerate only if changing pins).  
3. Build (Debug or Release).  
4. Flash via ST‑Link (Run → Debug).  
5. Open a serial terminal (115200 8N1 by default unless modified) or use the MATLAB script below.

To test the controllers with auto-generated code from Simulink:
1. Open the relevant `SIL_PIL_*.slx` model (e.g. `position/SIL_PIL_extern_pos.slx`).
2. Configure the Embedded Coder settings
3. Generate code and deploy to the Nucleo board via PIL workflow.
4. Open a serial terminal or use the MATLAB script for data logging.

## 8. Results Snapshot
The results are detailed in `report.pdf` with representative plots.

## License
Licensed under the BSD 3-Clause License. See `LICENSE` for details.

---

## 🔧 Hardware Summary (Reference)
* Nucleo STM32F401RE: ARM Cortex‑M4 @ 84 MHz, UART, multiple timers → PWM generation for H‑bridge.
* Gearmotor: 131.25:1 reduction; effective resolution 8400 counts / rev (64 CPR × gear ratio).
* Driver (X‑NUCLEO‑IHM04A1): Dual full H‑bridge; directional control + enable/PWM pins.
* ACS714: Hall effect current sensing enabling torque estimation.

---

Feel free to open issues / PRs for improvements or questions.
