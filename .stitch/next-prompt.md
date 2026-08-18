---
page: medication-record
---
A Medication Administration Record (eMAR) screen for the Vitalert Patient Monitoring System. Allows nurses to view active IV infusions, upcoming scheduled doses, scan patient wristbands, and log administered medications with timestamp and dosage verification.

**DESIGN SYSTEM (REQUIRED):**
- Platform: Mobile / Web Responsive, Clinical Telemetry Dashboard
- Theme: Clean Medical Light Mode
- Background: Surface Canvas (#F8F9FF)
- Surface Cards: Pure White (#FFFFFF) with 1px border (#E2E8F0)
- Primary Accent: Precision Teal (#007B7F) for active tabs, buttons, and links
- Text Primary: Deep Navy (#0B1C30)
- Text Secondary: Muted Slate (#64748B)
- Telemetry Metrics: Monospaced/Tabular numbers for vital values and dosage (mg, mL/hr)
- Status Semantics: Given (#2E7D32), Due Soon (#F59E0B), Overdue/Critical (#D32F2F)
- Typography: Inter for UI & Headings, JetBrains Mono for dosage and timestamps
- Corner Radius: 4px (small components), 8px–12px (cards and modal sheets)

**Page Structure:**
1. **Header:** Patient banner with Pedro Garcia (Bed 04-A), MRN: #89201, Allergy Warning (Penicillin)
2. **Scan & Verify Action Bar:** Barcode scanner button for patient wristband and medication vial
3. **Active Continuous Infusions:** Real-time IV pump rate (e.g. Norepinephrine 0.05 mcg/kg/min, Saline 0.9% 100 mL/hr)
4. **Scheduled Doses Timeline:** Chronological list of medications with time badges, dosage, route, and "Administer" CTA
5. **PRN / As-Needed Medications Section:** Expandable list of ordered PRN pain/nausea meds with last administered time
6. **Bottom Navigation Bar:** Global navigation with links to Dashboard, Patient Vitals, Alerts, Patient Log, and eMAR
