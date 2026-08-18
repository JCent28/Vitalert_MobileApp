# Vitalert Patient Monitoring System

## 1. Vision
Vitalert is a medical-grade real-time clinical monitoring application tailored for hospital nurses, intensivists, and healthcare providers. It provides continuous patient telemetry, live ECG/vitals monitoring, alert prioritization, and historical telemetry logging.

## 2. Project Information
- **Stitch Project ID:** `11127492466121189818`
- **Target Platform:** Mobile First (Responsive Web / Tablet / Desktop)
- **Primary Color:** `#007B7F` (Precision Teal)
- **Design Language:** Modern Clinical Minimalism (Inter + JetBrains Mono)

## 3. Architecture & Structure
```
vitalert/
├── .stitch/
│   ├── metadata.json   # Stitch project metadata & screen IDs
│   ├── DESIGN.md       # Visual design system specifications
│   ├── SITE.md         # Site vision, sitemap, and roadmap
│   ├── next-prompt.md  # Relay baton for next Stitch loop iteration
│   └── designs/        # Raw downloaded Stitch HTML/PNG outputs
│       ├── signin.html
│       ├── dashboard.html
│       ├── patient-vitals.html
│       ├── alerts.html
│       └── patient-log.html
└── site/public/        # Production interactive site with seamless routing
    ├── index.html      # Points to signin / dashboard
    ├── signin.html
    ├── dashboard.html
    ├── patient-vitals.html
    ├── alerts.html
    └── patient-log.html
```

## 4. Sitemap (Current Iteration - 5 Core Screens)
- [x] **Sign In (`signin.html`):** Secure clinical login with biometric auth, hospital staff badge scanner, and shift role selector.
- [x] **Dashboard (`dashboard.html`):** Ward overview with triage status, multi-bed telemetry grid (ICU Ward A), quick vitals overview, and urgent priority badges.
- [x] **Patient Vitals (`patient-vitals.html`):** Live telemetry detail for patient Pedro Garcia featuring real-time HR, SpO2, NIBP, Respiration, ECG lead waveform graph, and medication schedule.
- [x] **Clinical Alerts (`alerts.html`):** Real-time triage alert feed categorized by Critical, Warning, and Info with quick acknowledge / escalation actions.
- [x] **Patient Log (`patient-log.html`):** Historical telemetry logs, vital sign trend charts, event timestamps, nurse shift change notes, and PDF export summary.

## 5. Roadmap (Future Loop Backlog)
- [ ] **Medication Administration Record (eMAR):** Screen for scanning barcodes, administering doses, and logging medication infusions.
- [ ] **Shift Handover Report:** Structured SBAR (Situation, Background, Assessment, Recommendation) report generator.
- [ ] **Telemetry Device Pairing:** Bluetooth/NFC clinical sensor pairing and calibration interface.
- [ ] **Multi-Bed Central Telemetry View:** Split-screen multi-patient live wave stream view for nursing station monitors.

## 6. Creative Freedom Ideas
- Bedside Nurse Call Notification Hub
- Automated Early Warning Score (NEWS2 / MEWS) Calculator
- Code Blue Emergency Response Checklist
