# VITALERT – Dialysis Center Clinical Monitoring System

## 1. Project Overview
- **Stitch Project ID**: `projects/7366582551561146003`
- **Application**: Real-time nurse station dialysis monitoring app for NephroAsia Dialysis Center
- **Device Target**: Mobile (responsive tablet/desktop compatible)

## 2. Core Workflow & Use Cases
1. **Authentication**: Nurse / Doctor sign-in with Staff ID, Password, and Role selection.
2. **Floor Dashboard**: Live shift overview showing patient occupancy, normal/warning/critical distribution, search, and patient chair list.
3. **Patient Vitals & Trend Log**: Individual patient dialysis session details with real-time Chart.js charts for Pulse Rate (BPM) and Oxygen Saturation (SpO2), plus chronological timestamped table.
4. **Alerts Management**: Shift alert monitoring with Active vs. Acknowledged tabs, instant triage actions, and direct links to patient logs.

## 3. Sitemap
- [x] `index.html` – Sign In Screen
- [x] `dashboard.html` – Floor & Patient Overview Dashboard (Shift A)
- [x] `patient-log.html` – Detailed Patient Vitals, Graphs, and Session History
- [x] `alerts.html` – Active Critical & Warning Alerts Stream
- [x] `alerts-ack.html` – Acknowledged Alerts Archive

## 4. Roadmap & Next Iteration Backlog
- [ ] `add-patient.html` / Dedicated Intake Flow – Comprehensive patient admission and chair assignment wizard
- [ ] `patient-vitals-stream.html` – High-frequency multi-parameter waveform / telemetry view
- [ ] `shift-handover.html` – Nurse shift report summary & handover notes export
- [ ] `settings.html` – Center alert threshold configuration and nurse station preferences

## 5. Creative Freedom / Future Ideas
- Blood Pressure (MAP) & Ultrafiltration Rate (UFR) real-time dials
- Dialysis machine sensor telemetry pairing QR code scanner
- Emergency nurse call bell notification banner
