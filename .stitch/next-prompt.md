---
page: add-patient
---
A dedicated patient intake and chair assignment workflow screen for the VITALERT nurse station.

**DESIGN SYSTEM (REQUIRED):**
- **Theme**: Light Mode clinical monitoring dashboard
- **Primary Color**: #007D79 (Deep Teal), Accent: #10B981 (Live Emerald), Critical: #EF4444, Warning: #F59E0B
- **Background**: #F8FAFC, Card Surface: #FFFFFF with subtle border #E2E8F0 and soft shadow
- **Font**: Inter (sans-serif)
- **Header**: Top navigation bar with "VITALERT", subtext "NephroAsia Dialysis Center", and back navigation button.
- **Layout**: Mobile-first responsive container (max-w-md), clean rounded cards (rounded-xl), touch-friendly buttons.

**Page Structure:**
1. Header with back button to `dashboard.html` and title "New Patient Admission"
2. Patient Demographics section (Full Name, Medical Record Number / MRN, Age, Gender)
3. Treatment Station Allocation (Chair Selector grid 1-12 with occupied/available indicators)
4. Session Parameters (Target Ultrafiltration Volume, Treatment Duration, Dialyzer Type, Assigned Nurse)
5. Telemetry & Sensor Assignment (Bluetooth Sensor / Device ID pairing with auto-scan button)
6. Action Buttons: "Cancel" (links to dashboard) and primary "Start Treatment Session"
